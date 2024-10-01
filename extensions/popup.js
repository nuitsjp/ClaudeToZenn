console.log("Popup script started loading"); // ポップアップスクリプトの読み込み開始をログに記録

document.addEventListener('DOMContentLoaded', function() {
  console.log("Popup DOM loaded"); // ポップアップのDOMが読み込まれたことをログに記録
  const generateButton = document.getElementById('generateSummary'); // 'generateSummary'というIDを持つボタンを取得
  const copyButton = document.getElementById('publishArticle'); // 'publishArticle'というIDを持つボタンを取得

  // ボタンが見つからない場合、エラーメッセージをログに記録して処理を終了
  if (!generateButton || !copyButton) {
    console.log("One or more buttons not found");
    return;
  }

  // 'generateSummary'ボタンがクリックされたときのイベントリスナーを追加
  generateButton.addEventListener('click', function() {
    handleButtonClick('generateSummary');
  });

  // 'publishArticle'ボタンがクリックされたときのイベントリスナーを追加
  copyButton.addEventListener('click', function() {
    handleButtonClick('publishArticle');
  });

  function handleButtonClick(action) {
    console.log(action + " button clicked"); // ボタンがクリックされたことをログに記録

    // 現在のアクティブなタブを取得
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      if (chrome.runtime.lastError) {
        console.log("Error querying tabs: " + chrome.runtime.lastError.message); // タブ取得エラーをログに記録
        return;
      }
      console.log("Active tab: " + JSON.stringify(tabs[0])); // アクティブなタブ情報をログに記録
      // アクティブなタブにメッセージを送信
      chrome.tabs.sendMessage(tabs[0].id, {action: action}, function(response) {
        console.log("Response received in popup"); // ポップアップでレスポンスを受信したことをログに記録
        if (chrome.runtime.lastError) {
          console.log("Chrome runtime error: " + chrome.runtime.lastError.message); // Chromeランタイムエラーをログに記録
        }
      });
    });
  }
});

console.log("Popup script finished loading"); // ポップアップスクリプトの読み込み完了をログに記録
