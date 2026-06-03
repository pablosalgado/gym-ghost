const CACHE_NAME = "gym-ghost-static-v1"
const STATIC_ASSET_PATHS = ["/manifest.json", "/icon.png", "/icon.svg"]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSET_PATHS))
  )
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)))
    )
  )
  self.clients.claim()
})

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return

  const requestUrl = new URL(event.request.url)
  const isSameOrigin = requestUrl.origin === self.location.origin
  const isStaticAsset =
    event.request.destination === "script" ||
    event.request.destination === "style" ||
    event.request.destination === "image" ||
    requestUrl.pathname.startsWith("/assets/")

  if (!isSameOrigin || !isStaticAsset) return

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) return cachedResponse

      return fetch(event.request).then((networkResponse) => {
        if (!networkResponse.ok) return networkResponse

        const responseClone = networkResponse.clone()
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone))

        return networkResponse
      })
    })
  )
})
