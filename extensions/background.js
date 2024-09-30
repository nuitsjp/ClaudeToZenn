// Native Messaging Host の名前
const hostName = "jp.nuits.claude_to_zenn";

// Native Messaging Host との接続を管理
chrome.runtime.onConnect.addListener((port) => {
  if (port.name === "nativeMessaging") {
    port.onMessage.addListener((message) => {
      console.log("Received message from popup:", message);
      sendMessageToNativeHost(message, (response) => {
        port.postMessage(response);
      });
    });
  }
});

// Native Host にメッセージを送信
function sendMessageToNativeHost(message, callback) {
  chrome.runtime.sendNativeMessage(hostName, message, (response) => {
    console.log("Received response from native host:", response);
    if (chrome.runtime.lastError) {
      console.error(chrome.runtime.lastError);
      callback({ error: chrome.runtime.lastError.message });
    } else {
      callback(response);
    }
  });
}

// 初期化リスナー
chrome.runtime.onInstalled.addListener(() => {
  console.log("ClaudeToZenn extension installed.");
});

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "getMultilineString") {
    chrome.storage.sync.get('multilineString', function(data) {
      sendResponse({multilineString: data.multilineString});
    });
    return true;  // Will respond asynchronously
  }
});
