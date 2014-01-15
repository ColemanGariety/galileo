document.querySelector('pre').onclick = function () {
  selectText('install')
}

function selectText(containerid) {
  var range

  if (document.selection) {
    range = document.body.createTextRange();
    range.moveToElementText(document.getElementById(containerid));
    range.select();
  } else if (window.getSelection) {
    range = document.createRange();
    range.selectNode(document.getElementById(containerid));
    window.getSelection().addRange(range);
  }
}