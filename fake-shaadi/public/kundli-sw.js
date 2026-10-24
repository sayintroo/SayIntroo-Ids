// Keeps /kundli working offline at the booth: caches the page and its fonts.
const CACHE = 'rfk-v1';
const PAGE = '/kundli';

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.add(PAGE)).catch(() => {}));
  self.skipWaiting();
});
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  const u = new URL(e.request.url);
  const isPage = u.origin === location.origin && (u.pathname === '/kundli' || u.pathname === '/kundli.html');
  const isFont = u.hostname === 'fonts.googleapis.com' || u.hostname === 'fonts.gstatic.com';
  if (!isPage && !isFont) return;

  if (isPage) {
    // network first (3s), fall back to the cached copy
    e.respondWith(Promise.race([
      fetch(e.request).then((r) => { const cp = r.clone(); caches.open(CACHE).then((c) => c.put(PAGE, cp)); return r; }),
      new Promise((_, rej) => setTimeout(rej, 3000)),
    ]).catch(() => caches.match(PAGE).then((m) => m || fetch(e.request))));
  } else {
    e.respondWith(caches.match(e.request).then((m) => m || fetch(e.request).then((r) => {
      const cp = r.clone(); caches.open(CACHE).then((c) => c.put(e.request, cp)); return r;
    })));
  }
});
