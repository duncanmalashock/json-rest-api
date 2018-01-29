module Main exposing (..)

import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


articleDecoder : Decoder Article
articleDecoder =
    Pipeline.decode Article
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "userId" Decode.int


type alias IdRecord =
    { id : Int
    }


idRecordDecoder : Decoder IdRecord
idRecordDecoder =
    Pipeline.decode IdRecord
        |> Pipeline.required "id" Decode.int


emptyDecoder : Decoder {}
emptyDecoder =
    Pipeline.decode {}


encodeArticle : Article -> Encode.Value
encodeArticle article =
    Encode.object
        [ ( "id", Encode.int article.id )
        , ( "title", Encode.string article.title )
        , ( "body", Encode.string article.body )
        , ( "userId", Encode.int article.userId )
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Article =
    { id : Int
    , title : String
    , body : String
    , userId : Int
    }


type alias Model =
    { articles : List Article
    , error : Maybe Error
    }


type Msg
    = GetArticleIndex
    | GetArticleIndexResponse (Result Error (List Article))
    | PostArticle Article
    | PostArticleResponse (Result Error Article)
    | PutArticle Article
    | PutArticleResponse (Result Error Article)
    | DeleteArticle Article
    | DeleteArticleResponse (Result Error Article)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : ( Model, Cmd Msg )
init =
    ( { articles = []
      , error = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetArticleIndex ->
            ( model, getArticleIndex )

        GetArticleIndexResponse result ->
            case result of
                Ok value ->
                    ( { model | articles = value }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        PostArticle article ->
            ( model, postArticle article )

        PostArticleResponse result ->
            case result of
                Ok value ->
                    ( { model | articles = value :: model.articles }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        PutArticle article ->
            ( model, putArticle article )

        PutArticleResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        DeleteArticle article ->
            ( model, deleteArticle article )

        DeleteArticleResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )


put : String -> Http.Body -> Decoder a -> Http.Request a
put url body decoder =
    Http.request
        { method = "PUT"
        , headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Content-type" "application/json"
            ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


delete : String -> Http.Body -> Decoder a -> Http.Request a
delete url body decoder =
    Http.request
        { method = "DELETE"
        , headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Content-type" "application/json"
            ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


getArticleIndexUrl : String
getArticleIndexUrl =
    "https://jsonplaceholder.typicode.com/posts"


postArticleUrl : String
postArticleUrl =
    "https://jsonplaceholder.typicode.com/posts"


putArticleUrl : Int -> String
putArticleUrl id =
    "https://jsonplaceholder.typicode.com/posts/" ++ toString id


deleteArticleUrl : Int -> String
deleteArticleUrl id =
    "https://jsonplaceholder.typicode.com/posts/" ++ toString id


getArticleIndex : Cmd Msg
getArticleIndex =
    Http.get getArticleIndexUrl (Decode.list articleDecoder)
        |> Http.send GetArticleIndexResponse


postArticle : Article -> Cmd Msg
postArticle article =
    Http.post postArticleUrl (Http.jsonBody <| encodeArticle article) articleDecoder
        |> Http.send PostArticleResponse


putArticle : Article -> Cmd Msg
putArticle article =
    put (putArticleUrl article.id) (Http.jsonBody <| encodeArticle article) articleDecoder
        |> Http.send PutArticleResponse


deleteArticle : Article -> Cmd Msg
deleteArticle article =
    delete (deleteArticleUrl article.id) (Http.jsonBody <| encodeArticle article) articleDecoder
        |> Http.send DeleteArticleResponse


newArticle : Article
newArticle =
    { id = -1
    , title = "Blah!"
    , body = "Lorem ipsum"
    , userId = 0
    }


articleView : Article -> Html Msg
articleView article =
    div []
        [ text article.title
        , Html.button [ onClick (PutArticle article) ] [ text "Update" ]
        , Html.button [ onClick (DeleteArticle article) ] [ text "Delete" ]
        ]


view : Model -> Html Msg
view model =
    div [] <|
        [ Html.button [ onClick GetArticleIndex ] [ text "Load Articles" ]
        , Html.button [ onClick (PostArticle newArticle) ] [ text "Save New Article" ]
        ]
            ++ (List.map articleView model.articles)
