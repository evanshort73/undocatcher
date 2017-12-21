# undocatcher
programmatically replace text without erasing undo history

the problem: setting the `value` property of a `textarea` element erases its undo history. The [`execCommand` function](https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Editable_content#Executing_commands), which solves this problem for elements with the `contenteditable` attribute set, doesn't work for `textarea` elements.

the solution: we create a new `textarea` element everytime we want to programmatically edit the text. Ugh, I know. When the user presses Ctrl+Z and the current `textarea` has no more undo history, we replace it with the previous `textarea`.

does this actually work? can you actually detect when the `textarea` has no more undo history? what about supporting redo and making sure the cursor position is correct? can this all be done within Elm's Virtualdom framework? is it even worth the effort? I don't know let's find out
