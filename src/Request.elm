module Request exposing (get, post, patch, delete)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)


get : String -> Decoder a -> Http.Request a
get url decoder =
    standardRequest "GET" url Http.emptyBody decoder


post : String -> Http.Body -> Decoder a -> Http.Request a
post url body decoder =
    standardRequest "POST" url body decoder


patch : String -> Http.Body -> Decoder a -> Http.Request a
patch url body decoder =
    standardRequest "PATCH" url body decoder


delete : String -> Http.Body -> Decoder a -> Http.Request a
delete url body decoder =
    standardRequest "DELETE" url body decoder


standardRequest : String -> String -> Http.Body -> Decoder a -> Http.Request a
standardRequest verb url body decoder =
    Http.request
        { method = verb
        , headers =
            [ Http.header "Accept" "application/json"
            ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
