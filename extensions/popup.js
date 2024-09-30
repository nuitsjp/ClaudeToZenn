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
  const copyButton = document.getElementById('copyArtifacts');
  const statusDiv = document.getElementById('status');
  const summaryDiv = document.getElementById('summary');

  if (!generateButton || !copyButton) {
    debugLog("One or more buttons not found");
    return;
  }

  generateButton.addEventListener('click', function() {
    handleButtonClick('generateSummary', "Generating summary...", "Summary generated successfully");
  });

  copyButton.addEventListener('click', function() {
    handleButtonClick('copyArtifacts', "Copying artifacts...", "Artifacts copied successfully");
  });

  function handleButtonClick(action, startMessage, successMessage) {
    debugLog(action + " button clicked");
    statusDiv.textContent = startMessage;
    summaryDiv.textContent = "";

    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      if (chrome.runtime.lastError) {
        debugLog("Error querying tabs: " + chrome.runtime.lastError.message);
        return;
      }
      debugLog("Active tab: " + JSON.stringify(tabs[0]));
      chrome.tabs.sendMessage(tabs[0].id, {action: action}, function(response) {
        debugLog("Response received in popup");
        if (chrome.runtime.lastError) {
          debugLog("Chrome runtime error: " + chrome.runtime.lastError.message);
          statusDiv.textContent = "Error: " + chrome.runtime.lastError.message;
        }
      });
    });
  }
});

debugLog("Popup script finished loading");