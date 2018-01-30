module JsonApi
    exposing
        ( Collection
        , Msg(..)
        , initCollection
        , update
        )

import UrlSubstitution exposing (UrlSubstitutions)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


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


type Msg resource
    = GetIndex UrlSubstitutions
    | Post resource UrlSubstitutions
    | Patch resource UrlSubstitutions
    | Delete resource UrlSubstitutions
    | GetIndexResponse (Result Error (List resource))
    | PostResponse (Result Error resource)
    | PatchResponse (Result Error resource)
    | DeleteResponse (Result Error resource)


update : Msg resource -> Collection resource -> ( Collection resource, Cmd (Msg resource) )
update msg collection =
    case msg of
        GetIndex urlSubstitutions ->
            ( collection, getIndex collection urlSubstitutions )

        Post resource urlSubstitutions ->
            ( collection, post collection urlSubstitutions resource )

        Patch resource urlSubstitutions ->
            ( collection, patch collection urlSubstitutions resource )

        Delete resource urlSubstitutions ->
            ( collection, delete collection urlSubstitutions resource )

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


getIndex : Collection resource -> UrlSubstitutions -> Cmd (Msg resource)
getIndex collection urlSubstitutions =
    let
        url =
            collection.urls.getIndex
                |> UrlSubstitution.doUrlSubstitutions urlSubstitutions
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
                |> UrlSubstitution.doUrlSubstitutions urlSubstitutions
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
                |> UrlSubstitution.doUrlSubstitutions urlSubstitutions
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
                |> UrlSubstitution.doUrlSubstitutions urlSubstitutions
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
