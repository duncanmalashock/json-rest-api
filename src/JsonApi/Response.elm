module JsonApi.Response
    exposing
        ( handleGetIndexResponse
        , handleCreateResponse
        , handleUpdateResponse
        , handleDeleteResponse
        )

import RemoteData exposing (RemoteData)
import Http exposing (Error)
import List.Extra


type alias WebData a =
    RemoteData Error a


type alias Response a =
    Result Error a


handleGetIndexResponse : Response (List resource) -> WebData (List resource) -> WebData (List resource)
handleGetIndexResponse result collection =
    RemoteData.fromResult result


handleCreateResponse : Response resource -> WebData (List resource) -> WebData (List resource)
handleCreateResponse result collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> value :: c) collection

        Err _ ->
            collection


handleUpdateResponse : Response resource -> (resource -> resource -> Bool) -> WebData (List resource) -> WebData (List resource)
handleUpdateResponse result predicate collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> List.Extra.replaceIf (predicate value) value c) collection

        Err _ ->
            collection


handleDeleteResponse : Response resource -> (resource -> resource -> Bool) -> WebData (List resource) -> WebData (List resource)
handleDeleteResponse result predicate collection =
    case result of
        Ok value ->
            RemoteData.map (\c -> List.filter (predicate value) c) collection

        Err _ ->
            collection
