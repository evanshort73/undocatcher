port module Main exposing (main)

import UndoCatcher exposing (UndoCatcher)

import Dom
import Html exposing (Html, div, button)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick)
import Html.Lazy
import Task

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , update = update
    , subscriptions =
        always
          ( Sub.batch
              [ UndoCatcher.undoPort (always Undo)
              , UndoCatcher.redoPort (always Redo)
              ]
          )
    , view = Html.Lazy.lazy view
    }

type alias Model = UndoCatcher

init : ( Model, Cmd Msg )
init =
  ( UndoCatcher.fromString "hello", Cmd.none )

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
      ( UndoCatcher.update text model, Cmd.none )
    Replace ( start, stop, replacement ) ->
      ( UndoCatcher.replace start stop replacement model
      , Task.attempt (always NoOp) (Dom.focus "catcher")
      )
    Undo ->
      ( UndoCatcher.undo model
      , Task.attempt (always NoOp) (Dom.focus "catcher")
      )
    Redo ->
      ( UndoCatcher.redo model
      , Task.attempt (always NoOp) (Dom.focus "catcher")
      )

view : Model -> Html Msg
view model =
  div
    []
    [ Html.map TextChanged (UndoCatcher.view model)
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
