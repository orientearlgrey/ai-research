{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings on purpose: Flutter's service worker caches the app
// files client-side, which can serve a stale build after a redeploy. Study
// content must always match what was deployed.
_flutter.loader.load();
