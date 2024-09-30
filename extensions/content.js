console.log("ClaudeToZenn content script loaded");

function debugLog(message) {
  console.log("Content script: " + message);
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  debugLog("Message received: " + JSON.stringify(request));
  
  const actions = {
    generateSummary: generateAndRetrieveSummary,
    copyArtifacts: copyArtifactsButton
  };

  if (actions[request.action]) {
    debugLog(`Starting ${request.action}`);
    actions[request.action]()
      .then(summary => {
        debugLog(`Completed ${request.action}`);
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
  } catch (error) {
    debugLog("Error in generateAndRetrieveSummary: " + error.message);
    throw error;
  }
}

async function copyArtifactsButton() {
  try {
    // クリップボードの内容を読み取る（少し遅延を入れる）
    setTimeout(() => {
      readClipboard().then(text => {
        console.log('Clipboard contents:', text);

        // バックグラウンドスクリプトとの接続を確立
        port = chrome.runtime.connect({name: "nativeMessaging"});

        port.onMessage.addListener((message) => {
          summaryDiv.textContent = JSON.stringify(message);
        });

        port.postMessage(
          { 
            action: "post", 
            content: text,
            repositoryPath: "C:\\Repos\\Zenn"
          });

      }).catch(err => {
        console.error('Failed to read clipboard contents: ', err);
      });
    }, 500);  // 500ミリ秒の遅延（必要に応じて調整）
  } catch (error) {
    debugLog("Error in copyArtifactsButton: " + error.message);
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
  
  const url = chrome.runtime.getURL('prompt.txt');
  const response = await fetch(url);
  const promptText = await response.text();

  inputArea.textContent += promptText;
  const event = new InputEvent('input', {
    inputType: 'insertText',
    data: promptText,
    bubbles: true,
    cancelable: true,
  });
  inputArea.dispatchEvent(event);
  // 各行の入力後に遅延を入れる
  await new Promise(resolve => setTimeout(resolve, 50));

  debugLog("Prompt inputted");
}

async function insertNewline(element) {
  // Shift+Enterキーイベントを作成
  const shiftEnterEvent = new KeyboardEvent('keydown', {
    key: 'Enter',
    code: 'Enter',
    which: 13,
    keyCode: 13,
    bubbles: true,
    cancelable: true,
    shiftKey: true
  });

  element.dispatchEvent(shiftEnterEvent);

  // テキストエリアに改行を追加
  element.textContent += '\n';

  // inputイベントをディスパッチ
  const inputEvent = new InputEvent('input', {
    inputType: 'insertLineBreak',
    bubbles: true,
    cancelable: true,
  });
  element.dispatchEvent(inputEvent);

  // 改行の間に少し遅延を入れる
  await new Promise(resolve => setTimeout(resolve, 50));
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

function readClipboard() {
  return new Promise((resolve, reject) => {
    // まず、navigator.clipboard.readText()を試みる
    navigator.clipboard.readText().then(resolve).catch(() => {
      // 失敗した場合、document.execCommandを使用
      const textArea = document.createElement("textarea");
      document.body.appendChild(textArea);
      textArea.focus();
      document.execCommand('paste');
      const text = textArea.value;
      document.body.removeChild(textArea);
      resolve(text);
    });
  });
}