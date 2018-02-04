module JsonRestApi.Response
    exposing
        ( handleGetIndexResponse
        , handleCreateResponse
        , handleUpdateResponse
        , handleDeleteResponse
        )

{-| This module provides time-saving helpers for updating `resource`s from HTTP responses. To be used with `JsonRestApi.Request`.

Collections should be modeled as `RemoteData Http.Error (List resource)`.

# Response Helpers
@docs handleGetIndexResponse, handleCreateResponse, handleUpdateResponse, handleDeleteResponse

-}

import RemoteData exposing (RemoteData)
import Http exposing (Error)
import List.Extra


{-| Replace a `RemoteData Error (List resource)` with a new list if the `Result` is `Ok`.

    case msg of
        GetAllResponse result ->
            ( { model | articles = Response.handleGetIndexResponse result model.articles }, Cmd.none )

-}
handleGetIndexResponse : Result Error (List resource) -> RemoteData Error (List resource) -> RemoteData Error (List resource)
handleGetIndexResponse result collection =
    RemoteData.fromResult result


{-| Add a new `resource` to a `RemoteData Error (List resource)` if the `Result` is `Ok`.

    case msg of
        CreateRequest article ->
            ( model, Request.create articleApi article () CreateResponse )

-}
handleCreateResponse : Result Error resource -> RemoteData Error (List resource) -> RemoteData Error (List resource)
handleCreateResponse result collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> value :: c) collection

        Err _ ->
            collection


{-| Replace a `resource` with the matching `id` in a `RemoteData Error (List resource)` if the `Result` is `Ok`.

    case msg of
        UpdateRequest article ->
            ( model, Request.update articleApi article () article.id UpdateResponse )

-}
handleUpdateResponse : Result Error resource -> (resource -> resource -> Bool) -> RemoteData Error (List resource) -> RemoteData Error (List resource)
handleUpdateResponse result predicate collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> List.Extra.replaceIf (predicate value) value c) collection

        Err _ ->
            collection


{-| Remove the `resource` with the matching `id` from a `RemoteData Error (List resource)` if the `Result` is `Ok`.

    case msg of
        DeleteRequest article ->
            ( model, Request.delete articleApi article () article.id DeleteResponse )

-}
handleDeleteResponse : Result Error resource -> (resource -> resource -> Bool) -> RemoteData Error (List resource) -> RemoteData Error (List resource)
handleDeleteResponse result predicate collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> List.Extra.filterNot (predicate value) c) collection

        Err _ ->
            collection
