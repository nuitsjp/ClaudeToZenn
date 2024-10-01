console.log("Popup script started loading"); // ポップアップスクリプトの読み込み開始をログに記録

// デバッグ用のログ関数を定義
function debugLog(message) {
  console.log(message); // メッセージをコンソールに出力
  const statusDiv = document.getElementById('status'); // 'status'というIDを持つ要素を取得
  if (statusDiv) {
    statusDiv.textContent += message + "\n"; // 要素が存在する場合、メッセージを追加
  }
}

document.addEventListener('DOMContentLoaded', function() {
  debugLog("Popup DOM loaded"); // ポップアップのDOMが読み込まれたことをログに記録
  const generateButton = document.getElementById('generateSummary'); // 'generateSummary'というIDを持つボタンを取得
  const copyButton = document.getElementById('copyArtifacts'); // 'copyArtifacts'というIDを持つボタンを取得

  // ボタンが見つからない場合、エラーメッセージをログに記録して処理を終了
  if (!generateButton || !copyButton) {
    debugLog("One or more buttons not found");
    return;
  }

  // 'generateSummary'ボタンがクリックされたときのイベントリスナーを追加
  generateButton.addEventListener('click', function() {
    handleButtonClick('generateSummary', "Generating summary...", "Summary generated successfully");
  });

  // 'copyArtifacts'ボタンがクリックされたときのイベントリスナーを追加
  copyButton.addEventListener('click', function() {
    handleButtonClick('copyArtifacts', "Copying artifacts...", "Artifacts copied successfully");
  });

  function handleButtonClick(action, startMessage, successMessage) {
    debugLog(action + " button clicked"); // ボタンがクリックされたことをログに記録

    // 現在のアクティブなタブを取得
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      if (chrome.runtime.lastError) {
        debugLog("Error querying tabs: " + chrome.runtime.lastError.message); // タブ取得エラーをログに記録
        return;
      }
      debugLog("Active tab: " + JSON.stringify(tabs[0])); // アクティブなタブ情報をログに記録
      // アクティブなタブにメッセージを送信
      chrome.tabs.sendMessage(tabs[0].id, {action: action}, function(response) {
        debugLog("Response received in popup"); // ポップアップでレスポンスを受信したことをログに記録
        if (chrome.runtime.lastError) {
          debugLog("Chrome runtime error: " + chrome.runtime.lastError.message); // Chromeランタイムエラーをログに記録
        }
      });
    });
  }
});

debugLog("Popup script finished loading"); // ポップアップスクリプトの読み込み完了をログに記録
