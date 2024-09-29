chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "getMultilineString") {
    chrome.storage.sync.get('multilineString', function(data) {
      sendResponse({multilineString: data.multilineString});
    });
    return true;  // Will respond asynchronously
  }
});