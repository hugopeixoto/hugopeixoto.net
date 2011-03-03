
function toggle(node)
{
  node.style.display = node.style.display == 'block' ? 'none' : 'block';
  return false;
}

var input = "";
var pattern = /38384040373937396665$/;
window.document.onkeydown = function(e) {
  input += e ? e.keyCode : event.keyCode;
  if (input.match(pattern)) { alert('Hello'); input = ""; }
  if (input.length > 20)
    input = input.substring(input.length-20, input.length);
}

