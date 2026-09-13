export const ROOT_URL = 'https://storage.googleapis.com/joss-travel-ios.firebasestorage.app/data/';

export function getTripDetailsUrl(tripDetails: string): string {
  const root = ROOT_URL.endsWith('/') ? ROOT_URL : `${ROOT_URL}/`;
  const cleanDetails = tripDetails.replace(/\\/g, '/').replace(/^\/+|\/+$/g, '');
  return `${root}trips/${cleanDetails}/trip.json`;
}
