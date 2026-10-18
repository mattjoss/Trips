#!/usr/bin/env python3
"""Migrate existing Firebase Storage images:
1. Converts HEIC to JPEG.
2. Resizes large images to max dimension 2048 (without upscaling).
3. Generates smaller thumbnail versions with max dimension 640 (without upscaling).
4. Uploads both versions as image/jpeg with Firebase Storage download tokens.
5. Updates trip.json with the new large JPEG url and thumbnail_url.
6. Removes old unresized .heic files from Firebase Storage.
7. Leaves videos untouched.
"""

import json
import os
import re
import sqlite3
import subprocess
import tempfile
import urllib.parse
import urllib.request
import uuid

BUCKET = "joss-travel-ios.firebasestorage.app"

def get_access_token():
    db_path = os.path.expanduser("~/.config/gcloud/credentials.db")
    conn = sqlite3.connect(db_path)
    row = conn.cursor().execute("SELECT value FROM credentials WHERE account_id='matt@jossfamily.com'").fetchone()
    conn.close()
    if not row:
        raise RuntimeError("No GCP credentials found for matt@jossfamily.com")

    creds = json.loads(row[0])
    data = urllib.parse.urlencode({
        "client_id": creds["client_id"],
        "client_secret": creds["client_secret"],
        "refresh_token": creds["refresh_token"],
        "grant_type": "refresh_token"
    }).encode('utf-8')

    req = urllib.request.Request(creds["token_uri"], data=data)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode('utf-8'))["access_token"]

def gcs_get_object_metadata(token, path):
    url = f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(path, safe='')}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise

def gcs_download_bytes(token, path):
    url = f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(path, safe='')}?alt=media"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as resp:
        return resp.read()

def gcs_upload_bytes(token, path, data_bytes, content_type="image/jpeg", download_token=None, cache_control=None):
    if download_token is None:
        download_token = str(uuid.uuid4())

    boundary = f"===MIGRATE_{uuid.uuid4().hex}==="
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": f"multipart/related; boundary={boundary}"
    }

    metadata = {
        "name": path,
        "contentType": content_type,
        "metadata": {
            "firebaseStorageDownloadTokens": download_token
        }
    }
    if cache_control:
        metadata["cacheControl"] = cache_control

    body = (
        f"--{boundary}\r\n"
        f"Content-Type: application/json; charset=UTF-8\r\n\r\n"
        f"{json.dumps(metadata)}\r\n"
        f"--{boundary}\r\n"
        f"Content-Type: {content_type}\r\n\r\n"
    ).encode('utf-8') + data_bytes + f"\r\n--{boundary}--\r\n".encode('utf-8')

    url = f"https://storage.googleapis.com/upload/storage/v1/b/{BUCKET}/o?uploadType=multipart"
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode('utf-8'))

    firebase_url = f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o/{urllib.parse.quote(path, safe='')}?alt=media&token={download_token}"
    return firebase_url, download_token

def gcs_delete_object(token, path):
    url = f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(path, safe='')}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"}, method="DELETE")
    try:
        with urllib.request.urlopen(req) as resp:
            pass
        return True
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False
        raise

def get_image_dimensions(file_path):
    output = subprocess.check_output(["sips", "-g", "pixelWidth", "-g", "pixelHeight", file_path], text=True)
    w_match = re.search(r"pixelWidth:\s*(\d+)", output)
    h_match = re.search(r"pixelHeight:\s*(\d+)", output)
    if not w_match or not h_match:
        raise ValueError(f"Could not parse dimensions from sips output:\n{output}")
    return int(w_match.group(1)), int(h_match.group(1))

def process_image(input_bytes, max_dimension, quality=85):
    """Takes input image bytes (HEIC or JPEG or PNG), resizes so max dimension <= max_dimension,
    converts to JPEG, does NOT upscale if already smaller, and returns JPEG bytes."""
    with tempfile.TemporaryDirectory(prefix="sips-resize-") as tempdir:
        input_file = os.path.join(tempdir, "input")
        output_file = os.path.join(tempdir, "output.jpg")

        with open(input_file, "wb") as f:
            f.write(input_bytes)

        w, h = get_image_dimensions(input_file)
        orig_max = max(w, h)

        cmd = ["sips", "-s", "format", "jpeg", "-s", "formatOptions", str(quality)]
        if orig_max > max_dimension:
            cmd.extend(["-Z", str(max_dimension)])

        cmd.extend([input_file, "--out", output_file])
        subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        with open(output_file, "rb") as f:
            result_bytes = f.read()

        out_w, out_h = get_image_dimensions(output_file)
        return result_bytes, out_w, out_h, w, h

def extract_storage_path_from_url(url):
    if "/o/" not in url:
        return None
    raw_path = url.split("/o/")[1].split("?")[0]
    return urllib.parse.unquote(raw_path)

def main():
    print("=" * 60)
    print("Firebase Storage Image Migration: Convert to JPEG & Dual-Res (2048 / 640)")
    print("=" * 60)

    print("Authenticating with Google Cloud Storage...")
    token = get_access_token()
    print("Authentication successful.")

    # 1. Fetch trips list
    print("\nFetching data/trips.json...")
    trips_data = gcs_download_bytes(token, "data/trips.json")
    trips = json.loads(trips_data.decode('utf-8'))
    print(f"Found {len(trips)} trip(s) in trips.json.")

    for trip in trips:
        trip_id = trip["trip_details"]
        print(f"\n" + "-" * 50)
        print(f"Processing trip: '{trip.get('title')}' ({trip_id})")
        print("-" * 50)

        # A. Process Cover Image
        cover_path = f"data/trips/{trip_id}/cover.jpg"
        cover_meta = gcs_get_object_metadata(token, cover_path)
        if cover_meta:
            print(f"\n[Cover] Found {cover_path} ({int(cover_meta.get('size', 0)):,} bytes).")
            cover_token = cover_meta.get("metadata", {}).get("firebaseStorageDownloadTokens")
            cover_bytes = gcs_download_bytes(token, cover_path)

            # Resize 2048 JPEG
            cov2048, w2048, h2048, ow, oh = process_image(cover_bytes, max_dimension=2048)
            print(f"[Cover] Resized cover to 2048 max: {ow}x{oh} -> {w2048}x{h2048} ({len(cov2048):,} bytes)")
            gcs_upload_bytes(token, cover_path, cov2048, "image/jpeg", download_token=cover_token)

            # Also generate 640 cover
            cov640, w640, h640, _, _ = process_image(cover_bytes, max_dimension=640)
            cover_640_path = f"data/trips/{trip_id}/cover_640.jpg"
            print(f"[Cover] Created cover_640: {w640}x{h640} ({len(cov640):,} bytes)")
            gcs_upload_bytes(token, cover_640_path, cov640, "image/jpeg")

        # B. Process Trip Details
        details_path = f"data/trips/{trip_id}/trip.json"
        print(f"\n[Trip Details] Fetching {details_path}...")
        details_bytes = gcs_download_bytes(token, details_path)
        details = json.loads(details_bytes.decode('utf-8'))

        image_items_to_process = []
        for s_idx, segment in enumerate(details.get("segments", [])):
            for sec_idx, section in enumerate(segment.get("sections", [])):
                if section.get("type") == "media":
                    for m_idx, item in enumerate(section.get("media", [])):
                        if item.get("type") == "image":
                            image_items_to_process.append((s_idx, sec_idx, m_idx, item))
                        elif item.get("type") == "video":
                            print(f"[Video] Skipping video item in segment '{segment.get('name')}'")

        print(f"[Media] Found {len(image_items_to_process)} image(s) to process.")

        changed = False
        for idx, (s_idx, sec_idx, m_idx, item) in enumerate(image_items_to_process, start=1):
            url = item.get("url", "")
            orig_storage_path = extract_storage_path_from_url(url)
            if not orig_storage_path:
                print(f"[{idx}/{len(image_items_to_process)}] Warning: Could not parse storage path for {url}")
                continue

            base_path, orig_ext = os.path.splitext(orig_storage_path)
            # Remove any trailing _640 in case it was already a thumbnail
            clean_base = re.sub(r'_640$', '', base_path)

            large_path = f"{clean_base}.jpg"
            small_path = f"{clean_base}_640.jpg"

            print(f"\n[{idx}/{len(image_items_to_process)}] Processing: {os.path.basename(orig_storage_path)}")

            # Download original
            orig_bytes = gcs_download_bytes(token, orig_storage_path)
            orig_size = len(orig_bytes)

            # Generate 2048 JPEG
            large_bytes, lw, lh, ow, oh = process_image(orig_bytes, max_dimension=2048)
            print(f"   Large (max 2048): {ow}x{oh} -> {lw}x{lh} ({orig_size:,} -> {len(large_bytes):,} bytes, JPEG)")

            # Generate 640 JPEG
            small_bytes, sw, sh, _, _ = process_image(orig_bytes, max_dimension=640)
            print(f"   Small (max 640):  {ow}x{oh} -> {sw}x{sh} ({len(small_bytes):,} bytes, JPEG)")

            # Upload large JPEG
            large_url, _ = gcs_upload_bytes(token, large_path, large_bytes, "image/jpeg")

            # Upload small 640 JPEG
            small_url, _ = gcs_upload_bytes(token, small_path, small_bytes, "image/jpeg")

            # Update item in details
            section_ref = details["segments"][s_idx]["sections"][sec_idx]
            section_ref["media"][m_idx]["url"] = large_url
            section_ref["media"][m_idx]["thumbnail_url"] = small_url
            changed = True

            # If original was .heic, delete old HEIC from storage
            if orig_ext.lower() == ".heic" and orig_storage_path != large_path:
                print(f"   Deleting old HEIC file: {orig_storage_path}")
                gcs_delete_object(token, orig_storage_path)

        # C. Save updated trip.json
        if changed:
            print(f"\nSaving updated {details_path} to Firebase Storage...")
            updated_json_bytes = json.dumps(details, indent=2).encode('utf-8')
            gcs_upload_bytes(
                token,
                details_path,
                updated_json_bytes,
                content_type="application/json",
                cache_control="no-cache, no-store, must-revalidate"
            )
            print(f"Successfully updated {details_path}!")

    print("\n" + "=" * 60)
    print("MIGRATION COMPLETE: All images resized to max 2048, 640 thumbnails created, converted to JPEG, and trip.json updated.")
    print("=" * 60)

if __name__ == "__main__":
    main()
