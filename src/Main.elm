port module Main exposing (main)

import Dom
import Html exposing (Html, Attribute, div, textarea, button)
import Html.Attributes exposing
  (style, id, value, disabled, property, attribute)
import Html.Events exposing (onInput, onClick)
import Html.Keyed as Keyed
import Json.Encode
import Task

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , update = update
    , subscriptions =
        always (Sub.batch [ undo (always Undo), redo (always Redo) ])
    , view = view
    }

type alias Model =
  { frame : Frame
  , edits : List Edit
  , editCount : Int
  , futureEdits : List Edit
  }

type alias Edit =
  { before : Frame
  , after : Frame
  }

type alias Frame =
  { text : String
  , start : Int
  , stop : Int
  }

init : ( Model, Cmd Msg )
init =
  ( { frame =
        let text = "hello" in
          { text = text
          , start = String.length text
          , stop = String.length text
          }
    , edits = []
    , editCount = 0
    , futureEdits = []
    }
  , Cmd.none
  )

type Msg
  = NoOp
  | TextChanged String
  | Replace (Int, Int, String)
  | Undo
  | Redo

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )
    TextChanged text ->
      ( let frame = model.frame in
          { model | frame = { frame | text = text }}
      , Cmd.none
      )
    Replace ( start, stop, replacement ) ->
      ( let
          after =
            { text =
                String.concat
                  [ String.left start model.frame.text
                  , replacement
                  , String.dropLeft stop model.frame.text
                  ]
            , start = start + String.length replacement
            , stop = start + String.length replacement
            }
        in
          { model
          | frame = after
          , edits =
              { before =
                  { text = model.frame.text
                  , start = start
                  , stop = stop
                  }
              , after = after
              } ::
                model.edits
          , editCount = model.editCount + 1
          , futureEdits = []
          }
      , Task.attempt (always NoOp) (Dom.focus "catcher")
      )
    Undo ->
      case model.edits of
        [] ->
          ( model, Cmd.none )
        edit :: edits ->
          ( { model
            | frame = edit.before
            , edits = edits
            , editCount = model.editCount - 1
            , futureEdits = edit :: model.futureEdits
            }
          , Task.attempt (always NoOp) (Dom.focus "catcher")
          )
    Redo ->
      case model.futureEdits of
        [] ->
          ( model, Cmd.none )
        edit :: futureEdits ->
          ( { model
            | frame = edit.after
            , edits = edit :: model.edits
            , editCount = model.editCount + 1
            , futureEdits = futureEdits
            }
          , Task.attempt (always NoOp) (Dom.focus "catcher")
          )

port undo : (() -> msg) -> Sub msg

port redo : (() -> msg) -> Sub msg

view : Model -> Html Msg
view model =
  div
    []
    [ Keyed.node
        "div"
        [ style
            [ ( "width", "500px" )
            , ( "height", "200px" )
            , ( "position", "relative" )
            ]
        ]
        ( List.concat
            [ List.map2
                (viewHiddenFrame cancelUndo)
                ( List.range
                    (model.editCount - List.length model.edits)
                    (model.editCount - 1)
                )
                (List.map .before (List.reverse model.edits))
            , [ viewFrame model ]
            , List.map2
                (viewHiddenFrame cancelRedo)
                ( List.range
                    (model.editCount + 1)
                    (model.editCount + List.length model.futureEdits)
                )
                (List.map .after model.futureEdits)
            ]
        )
    , button
        [ onClick (Replace ( 1, 2, "ea" ))
        ]
        [ Html.text "e -> ea"
        ]
    , button
        [ onClick Undo
        , disabled (not (canUndo model))
        ]
        [ Html.text "Undo"
        ]
    , button
        [ onClick Redo
        , disabled (not (canRedo model))
        ]
        [ Html.text "Redo"
        ]
    , Html.text (toString model)
    ]

viewFrame : Model -> (String, Html Msg)
viewFrame model =
  ( toString model.editCount
  , textarea
      [ onInput TextChanged
      , attribute "onkeydown" "lockCatcher(event)"
      , attribute "oninput" "unlockCatcher(event)"
      , id "catcher"
      , value model.frame.text
      , property
          "selectionStart"
          (Json.Encode.int model.frame.start)
      , property
          "selectionEnd"
          (Json.Encode.int model.frame.stop)
      , property "lockedValue" Json.Encode.null
      , property
          "undoValue"
          ( case model.edits of
              [] -> Json.Encode.null
              edit :: _ -> (Json.Encode.string edit.after.text)
          )
      , property
          "redoValue"
          ( case model.futureEdits of
              [] -> Json.Encode.null
              edit :: _ -> (Json.Encode.string edit.before.text)
          )
      , style
          [ ( "width", "100%" )
          , ( "height", "100%" )
          , ( "position", "absolute" )
          , ( "top", "0px" )
          , ( "left", "0px" )
          , ( "box-sizing", "border-box" )
          , ( "margin", "0px" )
          ]
      ]
      []
  )

viewHiddenFrame : String -> Int -> Frame -> (String, Html Msg)
viewHiddenFrame inputScript i frame =
  ( toString i
  , textarea
      [ value frame.text
      , attribute "oninput" inputScript
      , property "lockedValue" (Json.Encode.string frame.text)
      , style
          [ ( "width", "100%" )
          , ( "height", "25%" )
          , ( "position", "absolute" )
          , ( "bottom", "0px" )
          , ( "left", "0px" )
          , ( "box-sizing", "border-box" )
          , ( "margin", "0px" )
          , ( "visibility", "hidden" )
          ]
      ]
      []
  )

cancelUndo : String
cancelUndo =
  "document.execCommand(\"redo\", true, null)"

cancelRedo : String
cancelRedo =
  "document.execCommand(\"undo\", true, null)"

canUndo : Model -> Bool
canUndo model =
  case model.edits of
    [] -> False
    edit :: _ -> model.frame.text == edit.after.text

canRedo : Model -> Bool
canRedo model =
  case model.futureEdits of
    [] -> False
    edit :: _ -> model.frame.text == edit.before.text
