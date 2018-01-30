module ApiCollection exposing (..)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Article exposing (Article, articleDecoder, encodeArticle)


type alias Model =
    { collection : List Article
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetArticleIndex ->
            ( model, getArticleIndex )

        GetArticleIndexResponse result ->
            case result of
                Ok value ->
                    ( { model | collection = value }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        PostArticle article ->
            ( model, postArticle article )

        PostArticleResponse result ->
            case result of
                Ok value ->
                    ( { model | collection = value :: model.collection }, Cmd.none )

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
