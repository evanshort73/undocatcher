port module Main exposing (main)

import Ports
import Theater exposing (Frame, Replacement)

import Html exposing (Html, div, button)
import Html.Events exposing (onClick)

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , update = update
    , subscriptions = always (Ports.text TextChanged)
    , view = view
    }

type alias Model = String

init : ( Model, Cmd Msg )
init =
  ( "hello"
  , Theater.init (Frame "hello" 5 5)
  )

type Msg
  = TextChanged String
  | Replace Replacement
  | UndoAndReplace Replacement
  | Undo
  | Redo

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TextChanged text ->
      ( text
      , Cmd.none
      )
    Replace replacement ->
      ( model
      , Theater.replace replacement
      )
    UndoAndReplace replacement ->
      ( model
      , Theater.undoAndReplace replacement
      )
    Undo ->
      ( model
      , Ports.undo ()
      )
    Redo ->
      ( model
      , Ports.redo ()
      )

view : Model -> Html Msg
view model =
  div
    []
    [ Theater.view
    , button
        [ onClick (Replace (Replacement 1 2 "ea"))
        ]
        [ Html.text "e -> ea"
        ]
    , button
        [ onClick (UndoAndReplace (Replacement 1 2 "eb"))
        ]
        [ Html.text "e -> eb"
        ]
    , button
        [ onClick Undo
        ]
        [ Html.text "Undo"
        ]
    , button
        [ onClick Redo
        ]
        [ Html.text "Redo"
        ]
    , Html.text model
    ]
