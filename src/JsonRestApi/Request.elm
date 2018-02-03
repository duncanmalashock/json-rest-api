module JsonRestApi.Request
    exposing
        ( Config
        , initConfig
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


type alias Config resource urlData =
    { decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , baseUrl : String
    , toSuffix : urlData -> String
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


initConfig :
    { decoder : Decoder resource
    , encoder : resource -> Encode.Value
    , baseUrl : String
    , toSuffix : urlData -> String
    , options : List ConfigOption
    }
    -> Config resource urlData
initConfig configData =
    { decoder = configData.decoder
    , encoder = configData.encoder
    , baseUrl = configData.baseUrl
    , toSuffix = configData.toSuffix
    , updateVerb = updateVerbFromOptions configData.options
    , headers = headersFromOptions configData.options
    }


header : String -> String -> ConfigOption
header field value =
    Header ( field, value )


usePatchForUpdate : ConfigOption
usePatchForUpdate =
    UsePatchForUpdate


headersFromOptions : List ConfigOption -> List ( String, String )
headersFromOptions options =
    ( "Accept", "application/json" )
        :: (List.concat (List.map headerFromOption options))


headerFromOption : ConfigOption -> List ( String, String )
headerFromOption option =
    case option of
        Header ( field, value ) ->
            [ ( field, value ) ]

        _ ->
            []


updateVerbFromOptions : List ConfigOption -> Verb
updateVerbFromOptions options =
    List.filter isUpdateVerbOption options
        |> List.take 1
        |> updateVerbFromList


isUpdateVerbOption : ConfigOption -> Bool
isUpdateVerbOption option =
    case option of
        UsePatchForUpdate ->
            True

        _ ->
            False


updateVerbFromList : List ConfigOption -> Verb
updateVerbFromList listHead =
    case listHead of
        [] ->
            Put

        x :: _ ->
            Patch


getAll : Config resource urlData -> (Result Error (List resource) -> msg) -> Cmd msg
getAll api responseMsg =
    standardRequest
        (verbToString Get)
        api.headers
        api.baseUrl
        Http.emptyBody
        (Http.expectJson (Decode.list api.decoder))
        |> Http.send responseMsg


create : Config resource urlData -> resource -> (Result Error resource -> msg) -> Cmd msg
create api resource responseMsg =
    standardRequest
        (verbToString Post)
        api.headers
        api.baseUrl
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


update : Config resource urlData -> resource -> urlData -> (Result Error resource -> msg) -> Cmd msg
update api resource urlData responseMsg =
    standardRequest
        (verbToString api.updateVerb)
        api.headers
        (api.baseUrl ++ (api.toSuffix urlData))
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


delete : Config resource urlData -> resource -> urlData -> (Result Error resource -> msg) -> Cmd msg
delete api resource urlData responseMsg =
    standardRequest
        (verbToString Delete)
        api.headers
        (api.baseUrl ++ (api.toSuffix urlData))
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
