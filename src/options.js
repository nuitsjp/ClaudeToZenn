document.addEventListener('DOMContentLoaded', function() {
  var textArea = document.getElementById('multilineString');
  var saveButton = document.getElementById('save');

  // Load saved settings
  chrome.storage.sync.get('multilineString', function(data) {
    if (data.multilineString) {
      textArea.value = data.multilineString;
    }
  });

  // Save settings
  saveButton.addEventListener('click', function() {
    var multilineString = textArea.value;
    chrome.storage.sync.set({multilineString: multilineString}, function() {
      console.log('Settings saved');
    });
  });
});