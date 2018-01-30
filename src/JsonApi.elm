module JsonApi
    exposing
        ( Collection
        , Msg(..)
        , initCollection
        , update
        )

import Request
import UrlSubstitution exposing (UrlSubstitutions)
import RemoteData exposing (RemoteData)
import List.Extra
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Http exposing (Error)


type alias Collection resource =
    { resources : RemoteData Error (List resource)
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
    { resources = RemoteData.NotAsked
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
            handleListResponse result
                (\newList _ -> newList)
                { collection | resources = RemoteData.fromResult result }

        PostResponse result ->
            handleSingleResponse result
                (\newResource _ list -> newResource :: list)
                collection

        PatchResponse result ->
            handleSingleResponse result
                (\newResource idAccessor list ->
                    List.Extra.replaceIf
                        (\item -> (idAccessor item) == (idAccessor newResource))
                        newResource
                        list
                )
                collection

        DeleteResponse result ->
            handleSingleResponse result
                (\newResource idAccessor list ->
                    List.filter
                        (\item -> (idAccessor item) == (idAccessor newResource))
                        list
                )
                collection


handleListResponse :
    Result Error (List resource)
    -> (List resource -> List resource -> List resource)
    -> Collection resource
    -> ( Collection resource, Cmd (Msg resource) )
handleListResponse result updateFn collection =
    case result of
        Ok value ->
            ( { collection
                | resources = RemoteData.map (updateFn value) collection.resources
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


handleSingleResponse :
    Result Error resource
    -> (resource -> (resource -> String) -> List resource -> List resource)
    -> Collection resource
    -> ( Collection resource, Cmd (Msg resource) )
handleSingleResponse result updateFn collection =
    case result of
        Ok value ->
            ( { collection
                | resources = RemoteData.map (updateFn value collection.idAccessor) collection.resources
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


getIndex : Collection resource -> UrlSubstitutions -> Cmd (Msg resource)
getIndex collection urlSubstitutions =
    let
        url =
            collection.urls.getIndex
                |> UrlSubstitution.doUrlSubstitutions urlSubstitutions
    in
        Request.get
            url
            Http.emptyBody
            (Decode.list collection.decoder)
            |> Http.send GetIndexResponse


post : Collection resource -> UrlSubstitutions -> resource -> Cmd (Msg resource)
post collection urlSubstitutions resource =
    let
        url =
            collection.urls.post
                |> UrlSubstitution.doUrlSubstitutions urlSubstitutions
    in
        Request.post
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
        Request.patch
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
        Request.delete
            url
            (Http.jsonBody <| collection.encoder resource)
            collection.decoder
            |> Http.send DeleteResponse
