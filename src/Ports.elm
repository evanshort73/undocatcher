port module Ports exposing
  (initTheater, replace, undoAndReplace, undo, redo, text)

import Json.Encode as Encode

port initTheater : Encode.Value -> Cmd msg
port replace : Encode.Value -> Cmd msg
port undoAndReplace : Encode.Value -> Cmd msg

port undo : () -> Cmd msg
port redo : () -> Cmd msg

port text : (String -> msg) -> Sub msg
