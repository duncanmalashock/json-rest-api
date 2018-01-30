module JsonApi exposing (Collection, Msg(..), update)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Collection resource =
    { collection : List resource
    , error : Maybe Error
    , decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , idAccessor : resource -> Int
    , urls : Urls
    }


type alias Urls =
    { getIndex : String
    , post : String
    , put : String
    , delete : String
    }


type Msg resource
    = GetIndex
    | GetIndexResponse (Result Error (List resource))
    | Post resource
    | PostResponse (Result Error resource)
    | Put resource
    | PutResponse (Result Error resource)
    | Delete resource
    | DeleteResponse (Result Error resource)


update : Msg resource -> Collection resource -> ( Collection resource, Cmd (Msg resource) )
update msg model =
    case msg of
        GetIndex ->
            ( model, getIndex model )

        GetIndexResponse result ->
            case result of
                Ok value ->
                    ( { model | collection = value }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        Post article ->
            ( model, post model article )

        PostResponse result ->
            case result of
                Ok value ->
                    ( { model
                        | collection = value :: model.collection
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        Put article ->
            ( model, put model article )

        PutResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        Delete article ->
            ( model, delete model article )

        DeleteResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )


putUrl : Int -> String
putUrl id =
    "https://jsonplaceholder.typicode.com/posts/" ++ toString id


deleteUrl : Int -> String
deleteUrl id =
    "https://jsonplaceholder.typicode.com/posts/" ++ toString id


getIndex : Collection resource -> Cmd (Msg resource)
getIndex model =
    Http.get model.urls.getIndex (Decode.list model.decoder)
        |> Http.send GetIndexResponse


post : Collection resource -> resource -> Cmd (Msg resource)
post model article =
    Http.post
        model.urls.post
        (Http.jsonBody <| model.encoder article)
        model.decoder
        |> Http.send PostResponse


put : Collection resource -> resource -> Cmd (Msg resource)
put model article =
    putRequest
        (putUrl <| model.idAccessor article)
        (Http.jsonBody <| model.encoder article)
        model.decoder
        |> Http.send PutResponse


delete : Collection resource -> resource -> Cmd (Msg resource)
delete model article =
    deleteRequest
        (deleteUrl <| model.idAccessor article)
        (Http.jsonBody <| model.encoder article)
        model.decoder
        |> Http.send DeleteResponse


putRequest : String -> Http.Body -> Decoder a -> Http.Request a
putRequest url body decoder =
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


deleteRequest : String -> Http.Body -> Decoder a -> Http.Request a
deleteRequest url body decoder =
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
