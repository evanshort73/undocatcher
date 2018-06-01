var theater = null;
var past = [];
var present = null;
var future = [];
var timeout = 0;
var timeoutIsRedo = false;

function createScene(index, frame) {
  let scene = document.createElement("textarea");
  scene.spellcheck = false;
  scene.style.position = "absolute";
  scene.style.top = "0";
  scene.style.bottom = "auto";
  scene.style.left = "0";
  scene.style.width = "100%"; // TODO: can we set right and bottom instead?
  scene.style.height = "100%";
  scene.style.boxSizing = "border-box";
  scene.style.margin = "0";
  //scene.dataset.gramm_editor = "true";
  scene.style.visibility = "visible";
  scene.firstFrame = frame;
  scene.lastFrame = null;
  scene.index = index;
  scene.value = frame.text;
  scene.addEventListener("keydown", handleKeydown);
  scene.addEventListener("input", handleInput);
  return scene;
}

function initTheater(frame) {
  theater = document.getElementById("theater");
  present = createScene(0, frame);
  theater.appendChild(present);
}

function hideScene(scene) {
  //scene.dataset.gramm_editor = "false";
  scene.style.visibility = "hidden";
  scene.style.height = "25%";
  scene.style.top = "auto";
  scene.style.bottom = "0";
}

function showScene(scene) {
  scene.dataset.gramm_editor = "true";
  scene.style.visibility = "visible";
  scene.style.height = "100%";
  scene.style.top = "0";
  scene.style.bottom = "auto";
}

function replace(replacement) {
  for (let i = 0; i < future.length; i++) {
    theater.removeChild(future[i]);
  }
  future = [];

  present.lastFrame = {
    text: present.value,
    selectionStart: replacement.selectionStart,
    selectionEnd: replacement.selectionEnd
  };
  hideScene(present);
  past.push(present);

  let cursorPos = replacement.selectionStart + replacement.text.length;
  let frame = {
    text:
      present.value.substring(0, replacement.selectionStart) +
      replacement.text +
      present.value.substring(replacement.selectionEnd),
    selectionStart: cursorPos,
    selectionEnd: cursorPos
  };
  present = createScene(present.index + 1, frame);
  theater.appendChild(present);
  // Edge ignores selection changes if the textarea isn't
  // part of the DOM yet
  present.selectionStart = frame.selectionStart;
  present.selectionEnd = frame.selectionEnd;
  present.focus()

  app.ports.text.send(present.value);
}

function undoAndReplace(replacement) {
  for (let i = 0; i < future.length; i++) {
    theater.removeChild(future[i]);
  }
  future = [];
  theater.removeChild(present);

  let previous = past[past.length - 1];
  previous.lastFrame = {
    text: previous.value,
    selectionStart: replacement.selectionStart,
    selectionEnd: replacement.selectionEnd
  };

  let cursorPos = replacement.selectionStart + replacement.text.length;
  let frame = {
    text:
      previous.value.substring(0, replacement.selectionStart) +
      replacement.text +
      previous.value.substring(replacement.selectionEnd),
    selectionStart: cursorPos,
    selectionEnd: cursorPos
  };
  present = createScene(present.index, frame);
  theater.appendChild(present);
  present.selectionStart = frame.selectionStart;
  present.selectionEnd = frame.selectionEnd;
  present.focus()

  app.ports.text.send(present.value);
}

function undo() {
  timeout = 0;

  if (past.length == 0) {
    return;
  }

  hideScene(present);
  future.push(present);

  present = past.pop();
  showScene(present);
  present.selectionStart = present.lastFrame.selectionStart
  present.selectionEnd = present.lastFrame.selectionEnd
  present.focus()

  app.ports.text.send(present.value);
}

function redo() {
  timeout = 0;

  if (future.length == 0) {
    return;
  }

  hideScene(present);
  past.push(present);

  present = future.pop();
  showScene(present);
  present.selectionStart = present.firstFrame.selectionStart
  present.selectionEnd = present.firstFrame.selectionEnd
  present.focus()

  app.ports.text.send(present.value);
}

function handleKeydown(event) {
  if (
    (event.which == 90 || (event.which == 89 && !event.shiftKey)) &&
    event.ctrlKey != event.metaKey &&
    !event.altKey
  ) {
    if (event.which == 90 && !event.shiftKey) {
      handleUndo(event);
    } else {
      handleRedo(event);
    }
  }
}

function handleUndo(event) {
  if (
    event.target.index == present.index &&
    event.target.value == event.target.firstFrame.text &&
    timeout == 0
  ) {
    timeout = setTimeout(undo, 5);
    timeoutIsRedo = false;
  }
}

function handleRedo(event) {
  if (
    event.target.index == present.index &&
    event.target.lastFrame != null &&
    event.target.value == event.target.lastFrame.text &&
    timeout == 0
  ) {
    timeout = setTimeout(redo, 5);
    timeoutIsRedo = true;
  }
}

function handleInput(event) {
  if (event.target.index == present.index) {
    if (timeout != 0) {
      // Check that value has changed because Firefox sends
      // an input event even when undo is disabled
      if (
        timeoutIsRedo ?
        event.target.value != event.target.lastFrame.text :
        event.target.value != event.target.firstFrame.text
      ) {
        clearTimeout(timeout);
        timeout = 0;
      }
    }
    app.ports.text.send(event.target.value);
  } else if (event.target.index < present.index) {
    if (event.target.value != event.target.lastFrame.text) {
      document.execCommand("redo", true, null);
    }
  } else if (event.target.index > present.index) {
    if (event.target.value != event.target.firstFrame.text) {
      document.execCommand("undo", true, null);
    }
  }
}
