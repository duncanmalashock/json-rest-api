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

import RemoteData exposing (WebData)
import Http exposing (Error)
import List.Extra


{-| Replace a `WebData (List resource)` with a new list if the `Result` is `Ok`.

    case msg of
        GetAllResponse result ->
            ( { model | articles = Response.handleGetIndexResponse result model.articles }, Cmd.none )

-}
handleGetIndexResponse : Result Error (List resource) -> WebData (List resource) -> WebData (List resource)
handleGetIndexResponse result collection =
    RemoteData.fromResult result


{-| Add a new `resource` to a `WebData (List resource)` if the `Result` is `Ok`.

    case msg of
        CreateResponse result ->
            ( { model | articles = Response.handleCreateResponse result model.articles }, Cmd.none )

-}
handleCreateResponse : Result Error resource -> WebData (List resource) -> WebData (List resource)
handleCreateResponse result collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> value :: c) collection

        Err _ ->
            collection


{-| Replace a `resource` with the matching `id` in a `WebData (List resource)` if the `Result` is `Ok`.

    case msg of
        UpdateResponse result ->
            ( { model | articles = Response.handleUpdateResponse result articlesEqual model.articles }, Cmd.none )

-}
handleUpdateResponse : Result Error resource -> (resource -> resource -> Bool) -> WebData (List resource) -> WebData (List resource)
handleUpdateResponse result predicate collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> List.Extra.replaceIf (predicate value) value c) collection

        Err _ ->
            collection


{-| Remove the `resource` with the matching `id` from a `WebData (List resource)` if the `Result` is `Ok`.

    case msg of
        DeleteResponse result ->
            ( { model | articles = Response.handleDeleteResponse result articlesEqual model.articles }, Cmd.none )

-}
handleDeleteResponse : Result Error resource -> (resource -> resource -> Bool) -> WebData (List resource) -> WebData (List resource)
handleDeleteResponse result predicate collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> List.Extra.filterNot (predicate value) c) collection

        Err _ ->
            collection
