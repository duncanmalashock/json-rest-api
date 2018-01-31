module JsonApi
    exposing
        ( Api
        , Msg(..)
        , initApi
        , update
        )

import Request
import UrlSubstitution exposing (UrlSubstitutions)
import RemoteData exposing (RemoteData)
import List.Extra
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Http exposing (Error)


type alias Webdata a =
    RemoteData Error a


type alias Api resource id =
    { resources : Webdata (List resource)
    , error : Maybe Error
    , decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , id : resource -> id
    , baseUrl : String
    , toSuffix : id -> String
    }


initApi : Decoder resource -> (resource -> Encode.Value) -> (resource -> id) -> String -> (id -> String) -> Api resource id
initApi decoder encoder id baseUrl toSuffix =
    { resources = RemoteData.NotAsked
    , error = Nothing
    , decoder = decoder
    , encoder = encoder
    , id = id
    , baseUrl = baseUrl
    , toSuffix = toSuffix
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


update : Msg resource -> Api resource id -> ( Api resource id, Cmd (Msg resource) )
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
    -> Api resource id
    -> ( Api resource id, Cmd (Msg resource) )
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
    -> Api resource id
    -> ( Api resource id, Cmd (Msg resource) )
handleSingleResponse result updateFn collection =
    case result of
        Ok value ->
            ( { collection
                | resources = RemoteData.map (updateFn value (collection.id >> toString)) collection.resources
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


getIndex : Api resource id -> UrlSubstitutions -> Cmd (Msg resource)
getIndex collection urlSubstitutions =
    Request.get
        collection.baseUrl
        (Decode.list collection.decoder)
        |> Http.send GetIndexResponse


post : Api resource id -> UrlSubstitutions -> resource -> Cmd (Msg resource)
post collection urlSubstitutions resource =
    Request.post
        collection.baseUrl
        (Http.jsonBody <| collection.encoder resource)
        collection.decoder
        |> Http.send PostResponse


patch : Api resource id -> UrlSubstitutions -> resource -> Cmd (Msg resource)
patch collection urlSubstitutions resource =
    Request.patch
        collection.baseUrl
        (Http.jsonBody <| collection.encoder resource)
        collection.decoder
        |> Http.send PatchResponse


delete : Api resource id -> UrlSubstitutions -> resource -> Cmd (Msg resource)
delete collection urlSubstitutions resource =
    Request.delete
        collection.baseUrl
        (Http.jsonBody <| collection.encoder resource)
        collection.decoder
        |> Http.send DeleteResponse
