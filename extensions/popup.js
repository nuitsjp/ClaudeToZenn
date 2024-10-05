console.log("Popup script started loading");

document.addEventListener('DOMContentLoaded', function() {
  console.log("Popup DOM loaded");
  const generateButton = document.getElementById('generateSummary');
  const publishButton = document.getElementById('publishArticle');

  if (!generateButton || !publishButton) {
    console.log("One or more buttons not found");
    return;
  }

  generateButton.addEventListener('click', function() {
    handleButtonClick('generateSummary');
  });

  publishButton.addEventListener('click', function() {
    checkRepositoryPathAndPublish();
  });

  function handleButtonClick(action) {
    console.log(action + " button clicked");

    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      if (chrome.runtime.lastError) {
        console.log("Error querying tabs: " + chrome.runtime.lastError.message);
        return;
      }
      console.log("Active tab: " + JSON.stringify(tabs[0]));
      chrome.tabs.sendMessage(tabs[0].id, {action: action}, function(response) {
        console.log("Response received in popup");
        if (chrome.runtime.lastError) {
          console.log("Chrome runtime error: " + chrome.runtime.lastError.message);
        }
      });
    });
  }

  function checkRepositoryPathAndPublish() {
    chrome.storage.sync.get('repositoryPath', function(data) {
      if (!data.repositoryPath) {
        alert('リポジトリパスが設定されていません。設定画面で設定してください。');
        // オプション：設定ページを開く
        if (chrome.runtime.openOptionsPage) {
          chrome.runtime.openOptionsPage();
        } else {
          window.open(chrome.runtime.getURL('options.html'));
        }
      } else {
        handleButtonClick('publishArticle');
      }
    });
  }
});

console.log("Popup script finished loading");