port module Theater exposing
  (Frame, init, Replacement, replace, undoAndReplace, view)

import Ports

import Html exposing (Html, div)
import Html.Attributes exposing (style, id)
import Json.Encode as Encode

type alias Frame =
  { text : String
  , selectionStart : Int
  , selectionEnd : Int
  }

init : Frame -> Cmd msg
init frame =
  Ports.initTheater
    ( Encode.object
        [ ( "text", Encode.string frame.text )
        , ( "selectionStart", Encode.int frame.selectionStart )
        , ( "selectionEnd", Encode.int frame.selectionEnd )
        ]
    )

type alias Replacement =
  { selectionStart : Int
  , selectionEnd : Int
  , text : String
  }

replace : Replacement -> Cmd msg
replace = Ports.replace << encodeReplacement

undoAndReplace : Replacement -> Cmd msg
undoAndReplace = Ports.undoAndReplace << encodeReplacement

encodeReplacement : Replacement -> Encode.Value
encodeReplacement replacement =
  Encode.object
    [ ( "selectionStart", Encode.int replacement.selectionStart )
    , ( "selectionEnd", Encode.int replacement.selectionEnd )
    , ( "text", Encode.string replacement.text )
    ]

view : Html msg
view =
  div
    [ id "theater"
    , style
        [ ( "width", "500px" )
        , ( "height", "200px" )
        , ( "position", "relative" )
        ]
    ]
    []
