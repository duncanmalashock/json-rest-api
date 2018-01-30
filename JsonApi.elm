module JsonApi
    exposing
        ( Collection
        , Msg
            ( GetIndex
            , Post
            , Patch
            , Delete
            )
        , initCollection
        , update
        )

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Dict
import Regex


type alias Collection resource =
    { resources : List resource
    , error : Maybe Error
    , decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , idAccessor : resource -> String
    , urls : Urls
    }


type alias Urls =
    { getIndex : String
    , post : String
    , patch : String
    , delete : String
    }


initCollection : Decoder resource -> (resource -> Encode.Value) -> (resource -> String) -> Urls -> Collection resource
initCollection decoder encoder idAccessor urls =
    { resources = []
    , error = Nothing
    , decoder = decoder
    , encoder = encoder
    , idAccessor = idAccessor
    , urls = urls
    }


type alias UrlSubstitutions =
    List ( String, String )


type Msg resource
    = GetIndex UrlSubstitutions
    | GetIndexResponse (Result Error (List resource))
    | Post resource UrlSubstitutions
    | PostResponse (Result Error resource)
    | Patch resource UrlSubstitutions
    | PatchResponse (Result Error resource)
    | Delete resource UrlSubstitutions
    | DeleteResponse (Result Error resource)


update : Msg resource -> Collection resource -> ( Collection resource, Cmd (Msg resource) )
update msg collection =
    case msg of
        GetIndex urlSubstitutions ->
            ( collection, getIndex collection urlSubstitutions )

        GetIndexResponse result ->
            case result of
                Ok value ->
                    ( { collection
                        | resources = value
                        , error = Nothing
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { collection
                        | error = Just error
                      }
                    , Cmd.none
                    )

        Post resource urlSubstitutions ->
            ( collection, post collection urlSubstitutions resource )

        PostResponse result ->
            case result of
                Ok value ->
                    ( { collection
                        | resources = value :: collection.resources
                        , error = Nothing
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { collection
                        | error = Just error
                      }
                    , Cmd.none
                    )

        Patch resource urlSubstitutions ->
            ( collection, patch collection urlSubstitutions resource )

        PatchResponse result ->
            case result of
                Ok value ->
                    ( collection, Cmd.none )

                Err error ->
                    ( { collection
                        | error = Just error
                      }
                    , Cmd.none
                    )

        Delete resource urlSubstitutions ->
            ( collection, delete collection urlSubstitutions resource )

        DeleteResponse result ->
            case result of
                Ok value ->
                    ( collection, Cmd.none )

                Err error ->
                    ( { collection
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
getIndex collection urlSubstitutions =
    let
        url =
            collection.urls.getIndex
                |> doUrlSubstitutions urlSubstitutions
    in
        Http.get
            url
            (Decode.list collection.decoder)
            |> Http.send GetIndexResponse


post : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
post collection urlSubstitutions resource =
    let
        url =
            collection.urls.post
                |> doUrlSubstitutions urlSubstitutions
    in
        Http.post
            url
            (Http.jsonBody <| collection.encoder resource)
            collection.decoder
            |> Http.send PostResponse


patch : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
patch collection urlSubstitutions resource =
    let
        url =
            collection.urls.patch
                |> doUrlSubstitutions urlSubstitutions
    in
        patchRequest
            url
            (Http.jsonBody <| collection.encoder resource)
            collection.decoder
            |> Http.send PatchResponse


delete : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
delete collection urlSubstitutions resource =
    let
        url =
            collection.urls.delete
                |> doUrlSubstitutions urlSubstitutions
    in
        deleteRequest
            url
            (Http.jsonBody <| collection.encoder resource)
            collection.decoder
            |> Http.send DeleteResponse


patchRequest : String -> Http.Body -> Decoder a -> Http.Request a
patchRequest url body decoder =
    Http.request
        { method = "PATCH"
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
