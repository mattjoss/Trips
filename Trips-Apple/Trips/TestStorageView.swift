import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TestStorageView: View {
    @StateObject private var storageManager = StorageManager()
    @State private var statusMessage: String = "Ready"
    @State private var downloadedImage: TripPlatformImage?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase Storage Test")
                .font(.title)
                .padding()
            
            Text(statusMessage)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Upload Test File") {
                uploadTestFile()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Download Test File") {
                downloadTestFile()
            }
            .buttonStyle(.bordered)
            
            if let image = downloadedImage {
                Image(tripImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .padding()
                Text("Downloaded Image")
                    .font(.caption)
            }
        }
        .padding()
    }
    
    func uploadTestFile() {
        statusMessage = "Uploading..."
        
        // Create a dummy image or text file
        // Let's create a simple text file for this test, or a small system image
        guard let data = TripPlatformImage(named: "test")?.pngData() else {
            statusMessage = "Failed to create test data"
            return
        }
        
        let path = "test/test.png"
        
        storageManager.upload(data: data, path: path) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    print("Download URL: \(url.absoluteString)")
                    statusMessage = "Upload success! URL: \(url.absoluteString)"
                case .failure(let error):
                    statusMessage = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func downloadTestFile() {
        statusMessage = "Downloading..."
        let path = "test/test.png"
        
        storageManager.download(path: path) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    statusMessage = "Download success! Size: \(data.count) bytes"
                    if let image = TripPlatformImage(data: data) {
                        downloadedImage = image
                    }
                case .failure(let error):
                    statusMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    TestStorageView()
}
