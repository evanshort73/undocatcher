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
  { text : String
  , history : List String
  , historyCount : Int
  , selection : Maybe (Int, Int)
  }

init : ( Model, Cmd Msg )
init =
  ( { text = "hello"
    , history = []
    , historyCount = 0
    , selection = Nothing
    }
  , Cmd.none
  )

type Msg
  = TextChanged String
  | SetText String
  | Undo

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TextChanged text ->
      ( { model | text = text }, Cmd.none )
    SetText text ->
      ( { model
        | text = text
        , history = model.text :: model.history
        , historyCount = model.historyCount + 1
        , selection =
            Just ( String.length text - 2, String.length text )
        }
      , Cmd.none
      )
    Undo ->
      ( case model.history of
          [] ->
            model
          text :: history ->
            { model
            | text = text
            , history = history
            , historyCount = model.historyCount - 1
            , selection = Nothing
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
          ( List.concat
              [ [ onInput TextChanged
                , value model.text
                , id "catcher"
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
              , case model.selection of
                  Nothing ->
                    []
                  Just ( start, stop ) ->
                    [ property "selectionStart" (Json.Encode.int start)
                    , property "selectionEnd" (Json.Encode.int stop)
                    ]
              ]
          )
          []
        ) ::
          List.indexedMap
            (viewPrevious model.historyCount)
            model.history
      )
    , button
        [ onClick (SetText (model.text ++ "lo"))
        ]
        [ Html.text "lo"
        ]
    , button
        [ onClick Undo
        ]
        [ Html.text "Undo"
        ]
    , Html.text (toString model)
    ]

viewPrevious : Int -> Int -> String -> (String, Html Msg)
viewPrevious historyCount i text =
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
      [ Html.text text
      ]
  )
