module Main exposing (main)

import Html exposing (Html, div, textarea, button)
import Html.Attributes exposing
  (style, id, value, disabled, property, attribute)
import Html.Events exposing (onInput, onClick, on)
import Html.Keyed as Keyed
import Json.Encode
import Json.Decode exposing (Decoder)

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
  , edits : List Edit
  , editCount : Int
  , futureEdits : List Edit
  , onZUp : Msg
  , onYUp : Msg
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
    , onZUp = NoOp
    , onYUp = NoOp
    }
  , Cmd.none
  )

type Msg
  = NoOp
  | TextChanged String
  | Replace (Int, Int, String)
  | Undo
  | Redo
  | KeyDown (String, Int)
  | KeyUp (String, Int)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )
    TextChanged text ->
      ( if text == model.frame.text then
          model
        else
          let frame = model.frame in
            { model
            | frame = { frame | text = text }
            , onZUp = NoOp
            , onYUp = NoOp
            }
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
      , Cmd.none
      )
    Undo ->
      ( case model.edits of
          [] ->
            { model
            | onZUp = NoOp
            , onYUp = NoOp
            }
          edit :: edits ->
            { model
            | frame = edit.before
            , edits = edits
            , editCount = model.editCount - 1
            , futureEdits = edit :: model.futureEdits
            , onZUp = NoOp
            , onYUp = NoOp
            }
      , Cmd.none
      )
    Redo ->
      ( case model.futureEdits of
          [] ->
            { model
            | onZUp = NoOp
            , onYUp = NoOp
            }
          edit :: futureEdits ->
            { model
            | frame = edit.after
            , edits = edit :: model.edits
            , editCount = model.editCount + 1
            , futureEdits = futureEdits
            , onZUp = NoOp
            , onYUp = NoOp
            }
      , Cmd.none
      )
    KeyDown ("c", 90) ->
      ( { model | onZUp = Undo }, Cmd.none )
    KeyDown ("cs", 90) ->
      ( { model | onZUp = Redo }, Cmd.none )
    KeyDown ("c", 89) ->
      ( { model | onYUp = Redo }, Cmd.none )
    KeyDown x ->
      ( model, Cmd.none )
    KeyUp (_, 90) ->
      update model.onZUp model
    KeyUp (_, 89) ->
      update model.onYUp model
    KeyUp _ ->
      ( model, Cmd.none )

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
                (viewHiddenFrame)
                ( List.range
                    (model.editCount - List.length model.edits)
                    (model.editCount - 1)
                )
                (List.map .before (List.reverse model.edits))
            , [ viewFrame model.editCount model.frame ]
            , List.map2
                (viewHiddenFrame)
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

viewFrame : Int -> Frame -> (String, Html Msg)
viewFrame i frame =
  ( toString i
  , textarea
      [ onInput TextChanged
      , on "keydown" (Json.Decode.map KeyDown decodeKeyEvent)
      , on "keyup" (Json.Decode.map KeyUp decodeKeyEvent)
      , value frame.text
      , id "catcher"
      , property
          "selectionStart"
          (Json.Encode.int frame.start)
      , property
          "selectionEnd"
          (Json.Encode.int frame.stop)
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
  )

viewHiddenFrame : Int -> Frame -> (String, Html Msg)
viewHiddenFrame i frame =
  ( toString i
  , textarea
      [ value frame.text
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

decodeKeyEvent : Json.Decode.Decoder (String, Int)
decodeKeyEvent =
  Json.Decode.map2
    (,)
    ( Json.Decode.map4
        concat4Strings
        (ifFieldThenString "ctrlKey" "c")
        (ifFieldThenString "metaKey" "c")
        (ifFieldThenString "altKey" "a")
        (ifFieldThenString "shiftKey" "s")
    )
    (Json.Decode.field "which" Json.Decode.int)

concat4Strings : String -> String -> String -> String -> String
concat4Strings x y z w =
  x ++ y ++ z ++ w

ifFieldThenString : String -> String -> Json.Decode.Decoder String
ifFieldThenString field s =
  Json.Decode.map (stringIfTrue s) (Json.Decode.field field Json.Decode.bool)

stringIfTrue : String -> Bool -> String
stringIfTrue s true =
  if true then s else ""
