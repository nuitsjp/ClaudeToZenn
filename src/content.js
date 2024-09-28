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
  
  const promptText = `ここまでの内容を簡潔なMarkdown形式のブログにまとめます。Artifactsとして作成してください。
その際、通常のマークダウンと異なり、先頭に次のコンテンツを埋め込んでください。

---
title: ""
emoji: "🌟"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---


titleには記事を端的に表すタイトルを。
topicsには関連技術を端的な英単語で記述します。複数ある場合は「, 」でつなげて複数記述してください。
例：　topics:[azure, powershell]

これらの後ろに、マークダウンで記事を書きます。

基本構造は

# 結論
# 解説
# 補足情報

として、まとめる内容に応じて適宜追加・削除してください。

ではお願いします。`;

  const promptLines = promptText.split('\n');

  for (let i = 0; i < promptLines.length; i++) {
    await typeLine(inputArea, promptLines[i]);
    if (i < promptLines.length - 1) {
      await insertNewline(inputArea);
    }
  }

  debugLog("Prompt inputted");
}

async function typeLine(element, line) {
  for (let char of line) {
    await typeCharacter(element, char);
  }
}

async function typeCharacter(element, char) {
  const event = new InputEvent('input', {
    inputType: 'insertText',
    data: char,
    bubbles: true,
    cancelable: true,
  });
  element.textContent += char;
  element.dispatchEvent(event);
  // 入力の間に少し遅延を入れる
  await new Promise(resolve => setTimeout(resolve, 10));
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