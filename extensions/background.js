// Native Messaging Host の名前
const hostName = "jp.nuits.claude_to_zenn";

// デフォルトの設定値
const defaultSettings = {
  repositoryPath: "",
  multilineString: ""
};

// 拡張機能のインストール時やアップデート時に実行される
chrome.runtime.onInstalled.addListener(() => {
  console.log("ClaudeToZenn extension installed or updated.");
  initializeDefaultSettings();
});

// デフォルト設定の初期化
function initializeDefaultSettings() {
  chrome.storage.sync.get(['repositoryPath', 'multilineString'], (result) => {
    if (!result.repositoryPath) {
      chrome.storage.sync.set({repositoryPath: defaultSettings.repositoryPath});
    }
    if (!result.multilineString) {
      // デフォルトのプロンプトテキストを読み込む
      fetch(chrome.runtime.getURL('prompt.txt'))
        .then(response => response.text())
        .then(text => {
          chrome.storage.sync.set({multilineString: text});
        })
        .catch(error => console.error('Error loading default prompt:', error));
    }
  });
}

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

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "getMultilineString") {
    chrome.storage.sync.get('multilineString', function(data) {
      sendResponse({multilineString: data.multilineString});
    });
    return true;  // Will respond asynchronously
  }
});