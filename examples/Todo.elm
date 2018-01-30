module Todo exposing (Todo, todoDecoder, encodeTodo)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


type alias Todo =
    { uid : String
    , title : String
    , order : Int
    , completed : Bool
    }


todoDecoder : Decoder Todo
todoDecoder =
    Pipeline.decode Todo
        |> Pipeline.required "uid" Decode.string
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "order" Decode.int
        |> Pipeline.required "completed" Decode.bool


encodeTodo : Todo -> Encode.Value
encodeTodo todo =
    Encode.object
        [ ( "uid", Encode.string todo.uid )
        , ( "title", Encode.string todo.title )
        , ( "order", Encode.int todo.order )
        , ( "completed", Encode.bool todo.completed )
        ]
