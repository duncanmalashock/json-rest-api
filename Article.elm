module Article exposing (Article, articleDecoder, encodeArticle)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


type alias Article =
    { id : Int
    , title : String
    , body : String
    , userId : Int
    }


articleDecoder : Decoder Article
articleDecoder =
    Pipeline.decode Article
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "userId" Decode.int


encodeArticle : Article -> Encode.Value
encodeArticle article =
    Encode.object
        [ ( "id", Encode.int article.id )
        , ( "title", Encode.string article.title )
        , ( "body", Encode.string article.body )
        , ( "userId", Encode.int article.userId )
        ]
