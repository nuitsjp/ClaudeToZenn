console.log("ClaudeToZenn content script loaded");

function debugLog(message) {
  console.log("Content script: " + message);
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  debugLog("Message received: " + JSON.stringify(request));
  if (request.action === "generateSummary") {
    debugLog("Starting generateAndRetrieveSummary");
    generateAndRetrieveSummary()
      .then(summary => {
        debugLog("Summary generated");
        sendResponse({ success: true, summary: summary });
      })
      .catch(error => {
        debugLog("Error: " + error.message);
        sendResponse({ success: false, error: error.message });
      });
    return true;  // 非同期レスポンスを示す
  }
});

async function generateAndRetrieveSummary() {
  try {
    debugLog("Waiting for input element");
    const inputElement = await waitForElement('div[contenteditable="true"]');
    debugLog("Input element found");
    await inputPrompt(inputElement);
    await pressEnter(inputElement);
    return await retrieveSummary();
  } catch (error) {
    debugLog("Error in generateAndRetrieveSummary: " + error.message);
    throw error;
  }
}

function waitForElement(selector) {
  return new Promise((resolve) => {
    debugLog("Starting waitForElement for: " + selector);
    const checkElement = () => {
      const element = document.querySelector(selector);
      if (element) {
        debugLog("Element found");
        resolve(element);
      } else {
        debugLog("Element not found, retrying in 500ms");
        setTimeout(checkElement, 500);
      }
    };
    checkElement();
  });
}

async function inputPrompt(inputArea) {
  debugLog("Inputting prompt");

  const prompt = `以下の内容でZenn用の記事を作成してください:
1. マークダウン形式で作成する
2. タイトルは「ClaudeとのQ&A」とする
3. 見出しは「はじめに」「Q&Aの内容」「まとめ」の3つとする
4. 「Q&Aの内容」では、ここまでの会話内容を要約して箇条書きにする
5. 記事の最後に「この記事はAI (Claude) を使って作成しました」と付け加える`;

  inputArea.textContent = prompt;
  inputArea.dispatchEvent(new Event('input', { bubbles: true }));
  debugLog("Prompt inputted");
}

async function pressEnter(element) {
  const enterEvent = new KeyboardEvent('keydown', {
    bubbles: true,
    cancelable: true,
    key: 'Enter',
    keyCode: 13
  });
  element.dispatchEvent(enterEvent);
  element.textContent += '\n';
  element.dispatchEvent(new Event('input', { bubbles: true }));
  await new Promise(resolve => setTimeout(resolve, 50)); // 改行後の短い遅延
}

async function submitPrompt(inputArea) {
  debugLog("Submitting prompt");

  // Enterキーイベントを作成
  const enterKeyEvent = new KeyboardEvent('keydown', {
    bubbles: true,
    cancelable: true,
    key: 'Enter',
    code: 'Enter',
    keyCode: 13,
    which: 13,
    shiftKey: false
  });

  // Enterキーイベントを発火
  inputArea.dispatchEvent(enterKeyEvent);
  debugLog("Enter key pressed for submission");

  // レスポンスを待つ
  await new Promise(resolve => setTimeout(resolve, 5000));
}

async function retrieveSummary() {
  debugLog("Retrieving summary");
  await waitForElement('.prose');
  const lastResponse = document.querySelector('.prose');
  if (!lastResponse) {
    throw new Error("Response not found");
  }

  debugLog("Summary retrieved");
  return lastResponse.innerText;
}