// Temporary: return null to avoid instantiating Record (some plugin versions
// define Record as abstract which causes compile-time errors). The UI is
// already guarded to handle a null recorder. To re-enable recording, update
// this factory to construct a concrete recorder instance from the plugin.
dynamic createRecorder() {
  return null;
}
