module CustomRequests exposing (patchRequest, deleteRequest)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)


patchRequest : String -> Http.Body -> Decoder a -> Http.Request a
patchRequest =
    standardRequest "PATCH"


deleteRequest : String -> Http.Body -> Decoder a -> Http.Request a
deleteRequest =
    standardRequest "DELETE"


standardRequest : String -> String -> Http.Body -> Decoder a -> Http.Request a
standardRequest verb url body decoder =
    Http.request
        { method = verb
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
