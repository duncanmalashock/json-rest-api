module JsonRestApi.Request
    exposing
        ( Config
        , config
        , header
        , usePatchForUpdate
        , getAll
        , create
        , update
        , delete
        )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Http exposing (Error)


type alias Config resource urlBaseData urlSuffixData =
    { decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , toBaseUrl : urlBaseData -> String
    , toSuffix : urlSuffixData -> String
    , updateVerb : Verb
    , headers : List ( String, String )
    }


type ConfigOption
    = Header ( String, String )
    | UsePatchForUpdate


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


config :
    { decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , toBaseUrl : urlBaseData -> String
    , toSuffix : urlSuffixData -> String
    , options : List ConfigOption
    }
    -> Config resource urlBaseData urlSuffixData
config configData =
    let
        newConfig =
            { decoder = configData.decoder
            , encoder = configData.encoder
            , toBaseUrl = configData.toBaseUrl
            , toSuffix = configData.toSuffix
            , updateVerb = Put
            , headers = [ ( "Accept", "application/json" ) ]
            }
    in
        List.foldl applyOption newConfig configData.options


applyOption : ConfigOption -> Config resource urlBaseData urlSuffixData -> Config resource urlBaseData urlSuffixData
applyOption option config =
    case option of
        Header newHeader ->
            { config | headers = newHeader :: config.headers }

        UsePatchForUpdate ->
            { config | updateVerb = Patch }


header : String -> String -> ConfigOption
header field value =
    Header ( field, value )


usePatchForUpdate : ConfigOption
usePatchForUpdate =
    UsePatchForUpdate


getAll : Config resource urlBaseData urlSuffixData -> urlBaseData -> (Result Error (List resource) -> msg) -> Cmd msg
getAll api urlBaseData responseMsg =
    standardRequest
        (verbToString Get)
        api.headers
        (api.toBaseUrl urlBaseData)
        Http.emptyBody
        (Http.expectJson (Decode.list api.decoder))
        |> Http.send responseMsg


create : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> (Result Error resource -> msg) -> Cmd msg
create api resource urlBaseData responseMsg =
    standardRequest
        (verbToString Post)
        api.headers
        (api.toBaseUrl urlBaseData)
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


update : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> urlSuffixData -> (Result Error resource -> msg) -> Cmd msg
update api resource urlBaseData urlSuffixData responseMsg =
    standardRequest
        (verbToString api.updateVerb)
        api.headers
        ((api.toBaseUrl urlBaseData) ++ (api.toSuffix urlSuffixData))
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


delete : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> urlSuffixData -> (Result Error resource -> msg) -> Cmd msg
delete api resource urlBaseData urlSuffixData responseMsg =
    standardRequest
        (verbToString Delete)
        api.headers
        ((api.toBaseUrl urlBaseData) ++ (api.toSuffix urlSuffixData))
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


standardRequest : String -> List ( String, String ) -> String -> Http.Body -> Http.Expect a -> Http.Request a
standardRequest verb headers url body expect =
    Http.request
        { method = verb
        , headers =
            List.map
                (\( field, value ) -> Http.header field value)
                headers
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , withCredentials = False
        }
