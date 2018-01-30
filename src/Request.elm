module Request exposing (get, post, patch, delete)

import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)


get : String -> Http.Body -> Decoder a -> Http.Request a
get =
    standardRequest "GET"


post : String -> Http.Body -> Decoder a -> Http.Request a
post =
    standardRequest "POST"


patch : String -> Http.Body -> Decoder a -> Http.Request a
patch =
    standardRequest "PATCH"


delete : String -> Http.Body -> Decoder a -> Http.Request a
delete =
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
