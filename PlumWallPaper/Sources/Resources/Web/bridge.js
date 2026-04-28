// bridge.js — JS ↔ Swift 通信桥
(function() {
  window.__pendingCallbacks = {};

  window.__bridgeCallback = function(callbackId, result) {
    const cb = window.__pendingCallbacks[callbackId];
    if (cb) {
      cb(result);
      delete window.__pendingCallbacks[callbackId];
    }
  };

  window.bridge = {
    call: function(action, params) {
      params = params || {};
      return new Promise(function(resolve, reject) {
        var callbackId = 'cb_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        window.__pendingCallbacks[callbackId] = function(result) {
          if (result.success) resolve(result.data);
          else reject(new Error(result.error || 'Unknown error'));
        };
        window.webkit.messageHandlers.bridge.postMessage(
          Object.assign({ action: action, callbackId: callbackId }, params)
        );
      });
    }
  };
})();
