module JsonApi exposing (Collection, Msg(..), update)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Dict
import Regex


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


type alias UrlSubstitutions =
    List ( String, String )


type Msg resource
    = GetIndex UrlSubstitutions
    | GetIndexResponse (Result Error (List resource))
    | Post resource UrlSubstitutions
    | PostResponse (Result Error resource)
    | Put resource UrlSubstitutions
    | PutResponse (Result Error resource)
    | Delete resource UrlSubstitutions
    | DeleteResponse (Result Error resource)


update : Msg resource -> Collection resource -> ( Collection resource, Cmd (Msg resource) )
update msg model =
    case msg of
        GetIndex urlSubstitutions ->
            ( model, getIndex model urlSubstitutions )

        GetIndexResponse result ->
            case result of
                Ok value ->
                    ( { model
                        | collection = value
                        , error = Nothing
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | error = Just error
                      }
                    , Cmd.none
                    )

        Post resource urlSubstitutions ->
            ( model, post model urlSubstitutions resource )

        PostResponse result ->
            case result of
                Ok value ->
                    ( { model
                        | collection = value :: model.collection
                        , error = Nothing
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | error = Just error
                      }
                    , Cmd.none
                    )

        Put resource urlSubstitutions ->
            ( model, put model urlSubstitutions resource )

        PutResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model
                        | error = Just error
                      }
                    , Cmd.none
                    )

        Delete resource urlSubstitutions ->
            ( model, delete model urlSubstitutions resource )

        DeleteResponse result ->
            case result of
                Ok value ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model
                        | error = Just error
                      }
                    , Cmd.none
                    )


urlSubstitutionRegex : Regex.Regex
urlSubstitutionRegex =
    Regex.regex ":[A-Za-z0-9_]+\\b"


doUrlSubstitutions : UrlSubstitutions -> String -> String
doUrlSubstitutions urlSubstitutions url =
    let
        dictionary =
            Dict.fromList urlSubstitutions
    in
        Regex.replace Regex.All
            urlSubstitutionRegex
            (\{ match } ->
                Dict.get match dictionary
                    |> Maybe.withDefault match
            )
            url


getIndex : Collection resource -> UrlSubstitutions -> Cmd (Msg resource)
getIndex model urlSubstitutions =
    let
        url =
            model.urls.getIndex
                |> doUrlSubstitutions urlSubstitutions
    in
        Http.get
            url
            (Decode.list model.decoder)
            |> Http.send GetIndexResponse


post : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
post model urlSubstitutions resource =
    let
        url =
            model.urls.post
                |> doUrlSubstitutions urlSubstitutions
    in
        Http.post
            url
            (Http.jsonBody <| model.encoder resource)
            model.decoder
            |> Http.send PostResponse


put : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
put model urlSubstitutions resource =
    let
        url =
            model.urls.put
                |> doUrlSubstitutions urlSubstitutions
    in
        putRequest
            url
            (Http.jsonBody <| model.encoder resource)
            model.decoder
            |> Http.send PutResponse


delete : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
delete model urlSubstitutions resource =
    let
        url =
            model.urls.delete
                |> doUrlSubstitutions urlSubstitutions
    in
        deleteRequest
            url
            (Http.jsonBody <| model.encoder resource)
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
