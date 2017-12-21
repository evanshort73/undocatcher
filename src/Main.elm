module Main exposing (main)

import Html exposing (Html, div, textarea, button)
import Html.Attributes exposing (style, id, value, property, attribute)
import Html.Events exposing (onInput, onClick)
import Html.Keyed as Keyed
import Json.Encode

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , update = update
    , subscriptions = always Sub.none
    , view = view
    }

type alias Model =
  { frame : Frame
  , history : List Frame
  , historyCount : Int
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
    , history = []
    , historyCount = 0
    }
  , Cmd.none
  )

type Msg
  = TextChanged String
  | Replace (Int, Int, String)
  | Undo

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TextChanged text ->
      ( let frame = model.frame in
          { model | frame = { frame | text = text } }
      , Cmd.none
      )
    Replace ( start, stop, replacement ) ->
      ( let frame = model.frame in
          { model
          | frame =
              { text =
                  String.concat
                    [ String.left start frame.text
                    , replacement
                    , String.dropLeft stop frame.text
                    ]
              , start = start + String.length replacement
              , stop = start + String.length replacement
              }
          , history =
              { frame | start = start, stop = stop } ::
                model.history
          , historyCount = model.historyCount + 1
          }
      , Cmd.none
      )
    Undo ->
      ( case model.history of
          [] ->
            model
          frame :: history ->
            { model
            | frame = frame
            , history = history
            , historyCount = model.historyCount - 1
            }
      , Cmd.none
      )

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
        ( ( toString (model.historyCount + 1)
          , textarea
              [ onInput TextChanged
              , value model.frame.text
              , id "catcher"
              , property
                  "selectionStart"
                  (Json.Encode.int model.frame.start)
              , property
                  "selectionEnd"
                  (Json.Encode.int model.frame.stop)
              , attribute "onselect" "event.target.focus()"
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
          ) ::
            List.indexedMap
              (viewPrevious model.historyCount)
              model.history
      )
    , button
        [ onClick (Replace ( 1, 2, "ea" ))
        ]
        [ Html.text "e -> ea"
        ]
    , button
        [ onClick Undo
        ]
        [ Html.text "Undo"
        ]
    , Html.text (toString model)
    ]

viewPrevious : Int -> Int -> Frame -> (String, Html Msg)
viewPrevious historyCount i frame =
  ( toString (historyCount - i)
  , textarea
      [ style
          [ ( "width", "100%" )
          , ( "height", "100%" )
          , ( "position", "absolute" )
          , ( "top", "0px" )
          , ( "left", "0px" )
          , ( "box-sizing", "border-box" )
          , ( "margin", "0px" )
          , ( "visibility", "hidden" )
          ]
      ]
      []
  )
