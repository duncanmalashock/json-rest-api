module JsonApi.Request
    exposing
        ( Config
        , initConfig
        , usePatchForUpdate
        , getAll
        , create
        , update
        , delete
        )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Http exposing (Error)


type alias Config resource urlData =
    { decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , baseUrl : String
    , toSuffix : urlData -> String
    , updateVerb : Verb
    }


usePatchForUpdate : Config resource urlData -> Config resource urlData
usePatchForUpdate config =
    { config
        | updateVerb = Patch
    }


type Verb
    = Get
    | Post
    | Put
    | Patch
    | Delete


verbToString : Verb -> String
verbToString verb =
    case verb of
        Get ->
            "GET"

        Post ->
            "POST"

        Put ->
            "PUT"

        Patch ->
            "PATCH"

        Delete ->
            "DELETE"


initConfig :
    { decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , baseUrl : String
    , toSuffix : urlData -> String
    }
    -> Config resource urlData
initConfig configData =
    { decoder = configData.decoder
    , encoder = configData.encoder
    , baseUrl = configData.baseUrl
    , toSuffix = configData.toSuffix
    , updateVerb = Put
    }


getAll : Config resource urlData -> (Result Error (List resource) -> msg) -> Cmd msg
getAll api responseMsg =
    standardRequest
        (verbToString Get)
        api.baseUrl
        Http.emptyBody
        (Decode.list api.decoder)
        |> Http.send responseMsg


create : Config resource urlData -> resource -> (Result Error resource -> msg) -> Cmd msg
create api resource responseMsg =
    standardRequest
        (verbToString Post)
        api.baseUrl
        (Http.jsonBody <| api.encoder resource)
        api.decoder
        |> Http.send responseMsg


update : Config resource urlData -> resource -> urlData -> (Result Error resource -> msg) -> Cmd msg
update api resource urlData responseMsg =
    standardRequest
        (verbToString api.updateVerb)
        (api.baseUrl ++ (api.toSuffix urlData))
        (Http.jsonBody <| api.encoder resource)
        api.decoder
        |> Http.send responseMsg


delete : Config resource urlData -> resource -> urlData -> (Result Error resource -> msg) -> Cmd msg
delete api resource urlData responseMsg =
    standardRequest
        (verbToString Delete)
        (api.baseUrl ++ (api.toSuffix urlData))
        (Http.jsonBody <| api.encoder resource)
        api.decoder
        |> Http.send responseMsg


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
