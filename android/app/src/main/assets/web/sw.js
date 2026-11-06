// Service Worker for Guitar Chord Studio v2
// Provides offline support, subpath compatibility, and instant updates

const getBasePath = () => {
  const path = self.location.pathname;
  return path.substring(0, path.lastIndexOf('/') + 1);
};

const BASE = getBasePath();
// Pages apps share an origin, not a cache namespace. Never evict another app's data.
const CACHE_PREFIX = `guitar-studio:${BASE}:`;
// C9UUorEE is replaced at build time with the bundle hash (scripts/stamp-sw.mjs)
const CACHE_NAME = `${CACHE_PREFIX}C9UUorEE`;
// Recordings keep their file names between releases, so they live in a cache that releases do not clear.
// Changed recordings still update: every use re-checks the file in the background.
const SOUND_CACHE = `${CACHE_PREFIX}saved-sounds`;
const isSound = (url) => url.pathname.startsWith(BASE + 'audio/');
// Accounts build (server/): login pages and the account API always go to the network, never to a cache.
const SERVER_ONLY = /^(?:api|auth)(?:\/|$)|^(?:login|signup|verify|forgot|reset|account|admin|privacy|delete-account)(?:\/|$)/;
const isServerOnly = (url) => SERVER_ONLY.test(url.pathname.slice(BASE.length));
// Song practice's AI files (about 86 MB, versioned by name) are saved by the app itself, once; caching them here
// as well would keep a second copy and download them again in the background on every use.
const SAVED_BY_APP = /^(?:models\/separation\/|ml\/onnxruntime-web-[^/]+\/[^/]+\.wasm$)/;
const isSavedByApp = (url) => SAVED_BY_APP.test(url.pathname.slice(BASE.length));
// A redirect (for example to the login page) or an error is never saved as an app file.
const cacheable = (response) => response.ok && !response.redirected;
const STATIC_ASSETS = [
  BASE,
  BASE + 'index.html',
  BASE + 'manifest.json',
  BASE + 'icon-192.png',
  BASE + 'icon-512.png',
  BASE + 'all_chord_shapes.js',
  BASE + 'song_catalog_data.js'
];

// Install - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS).catch((err) => {
        console.warn('Pre-caching warning:', err);
      });
    })
  );
  self.skipWaiting();
});

// Activate - move saved recordings out of older releases' caches, clear those caches, take control immediately
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(async (cacheNames) => {
      const old = cacheNames.filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME && name !== SOUND_CACHE);
      const sounds = await caches.open(SOUND_CACHE);
      for (const name of old) {
        try {
          const cache = await caches.open(name);
          for (const request of await cache.keys()) {
            if (!isSound(new URL(request.url)) || await sounds.match(request)) continue;
            const response = await cache.match(request);
            if (response) await sounds.put(request, response);
          }
        } catch (err) {
          console.warn('Could not keep saved sounds from', name, err);
        }
        console.log('Clearing old cache:', name);
        await caches.delete(name);
      }
    }).then(() => self.clients.claim())
  );
});

// Fetch handler
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin || !url.pathname.startsWith(BASE)) return;
  if (isServerOnly(url) || isSavedByApp(url)) return;

  // For HTML navigation requests: Network First, falling back to cache
  if (event.request.mode === 'navigate' || event.request.destination === 'document') {
    const fallback = BASE + 'index.html';
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (cacheable(networkResponse)) {
            const clone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return networkResponse;
        })
        .catch(() => {
          return caches.open(CACHE_NAME).then(async (cache) =>
            (await cache.match(event.request)) || (await cache.match(fallback)) || Response.error());
        })
    );
    return;
  }

  // For JS, CSS, media: Cache First, update in background (Stale-While-Revalidate)
  event.respondWith(
    caches.open(isSound(url) ? SOUND_CACHE : CACHE_NAME).then(async (cache) => {
      const cachedResponse = await cache.match(event.request);
      const fetchPromise = fetch(event.request).then((networkResponse) => {
        if (cacheable(networkResponse)) {
          const clone = networkResponse.clone();
          cache.put(event.request, clone);
        }
        return networkResponse;
      }).catch(() => Response.error());

      return cachedResponse || fetchPromise;
    })
  );
});

// Background sync for practice sessions (when online)
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-practice-sessions') {
    event.waitUntil(syncPracticeSessions());
  }
});

async function syncPracticeSessions() {
  // Implementation would sync localStorage data to server
  // For now, just log
  console.log('Background sync triggered for practice sessions');
}