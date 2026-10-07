{{flutter_js}}
{{flutter_build_config}}

(async () => {
  // Flutter's legacy service worker can keep an old main.dart.js active after
  // a deployment. Remove it and its cache before loading the current build.
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  if ('caches' in window) {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
  }

  for (const build of _flutter.buildConfig.builds) {
    if (build.mainJsPath) {
      build.mainJsPath = `${build.mainJsPath}?v=20261007-chart-width`;
    }
  }

  await _flutter.loader.load();
})();
