console.log("Popup script started loading");

function debugLog(message) {
  console.log(message);
  const statusDiv = document.getElementById('status');
  if (statusDiv) {
    statusDiv.textContent += message + "\n";
  }
}

debugLog("Popup script loaded");

document.addEventListener('DOMContentLoaded', function() {
  debugLog("Popup DOM loaded");
  const generateButton = document.getElementById('generateSummary');
  const statusDiv = document.getElementById('status');
  const summaryDiv = document.getElementById('summary');

  if (!generateButton) {
    debugLog("Generate Summary button not found");
    return;
  }

  generateButton.addEventListener('click', function() {
    debugLog("Generate Summary button clicked");
    statusDiv.textContent = "Generating summary...";
    summaryDiv.textContent = "";

    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      if (chrome.runtime.lastError) {
        debugLog("Error querying tabs: " + chrome.runtime.lastError.message);
        return;
      }
      debugLog("Active tab: " + JSON.stringify(tabs[0]));
      chrome.tabs.sendMessage(tabs[0].id, {action: "generateSummary"}, function(response) {
        debugLog("Response received in popup: " + JSON.stringify(response));
        if (chrome.runtime.lastError) {
          debugLog("Chrome runtime error: " + chrome.runtime.lastError.message);
          statusDiv.textContent = "Error: " + chrome.runtime.lastError.message;
        } else if (response && response.success) {
          statusDiv.textContent = "Summary generated successfully";
          summaryDiv.textContent = response.summary;
        } else {
          statusDiv.textContent = "Error: " + (response ? response.error : "Unknown error");
        }
      });
    });
  });
});

debugLog("Popup script finished loading");