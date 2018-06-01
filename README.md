# undocatcher
programmatically replace text without erasing undo history

the problem: setting the `value` property of a `textarea` element erases its undo history. The [`execCommand` function](https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Editable_content#Executing_commands), which solves this problem for elements with the `contenteditable` attribute set, doesn't work for `textarea` elements.

the solution: we create a new `textarea` element everytime we want to programmatically edit the text. Ugh, I know. When the user presses Ctrl+Z and the current `textarea` has no more undo history, we replace it with the previous `textarea`.

currently this demo seems to work correctly in Firefox, Chrome, and Edge. The only unexpected behavior is that after you edit manually, then undo, then replace text programmatically, then undo again, redo will put back the manual edit instead of the programmatical edit. I don't think there's any way to fix this, at least not on Firefox.

TODO: for Chrome, use the input event with `inputType == "historyUndo"` received by a hidden `textarea` to trigger the `Undo` action instead of relying on the keydown event. This will allow the user to undo even when the `textarea` is not focused, which is the expected behavior in Chrome.
