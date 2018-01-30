module ApiCollection exposing (..)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Article exposing (Article, articleDecoder, encodeArticle)


type alias Model =
    { collection : List Article
    , error : Maybe Error
    , decoder : Decoder Article
    , encoder : Article -> Encode.Value
    , idAccessor : Article -> Int
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
            ( model, getArticleIndex model )

        GetArticleIndexResponse result ->
            case result of
                Ok value ->
                    ( { model | collection = value }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        PostArticle article ->
            ( model, postArticle model article )

        PostArticleResponse result ->
            case result of
                Ok value ->
                    ( { model | collection = value :: model.collection }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        PutArticle article ->
            ( model, putArticle model article )

        PutArticleResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        DeleteArticle article ->
            ( model, deleteArticle model article )

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


getArticleIndex : Model -> Cmd Msg
getArticleIndex model =
    Http.get getArticleIndexUrl (Decode.list model.decoder)
        |> Http.send GetArticleIndexResponse


postArticle : Model -> Article -> Cmd Msg
postArticle model article =
    Http.post postArticleUrl (Http.jsonBody <| model.encoder article) model.decoder
        |> Http.send PostArticleResponse


putArticle : Model -> Article -> Cmd Msg
putArticle model article =
    put (putArticleUrl <| model.idAccessor article) (Http.jsonBody <| model.encoder article) model.decoder
        |> Http.send PutArticleResponse


deleteArticle : Model -> Article -> Cmd Msg
deleteArticle model article =
    delete (deleteArticleUrl <| model.idAccessor article) (Http.jsonBody <| model.encoder article) model.decoder
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
