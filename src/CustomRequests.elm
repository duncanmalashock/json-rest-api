module CustomRequests exposing (patchRequest, deleteRequest)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)


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
