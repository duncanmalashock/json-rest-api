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

{-| This module provides time-saving helpers for configuring and sending HTTP requests.

# Config
@docs Config, config, header, usePatchForUpdate

# Request Helpers
@docs getAll, create, update, delete

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Http exposing (Error)


{-| Basic settings for how URLs are constructed with dynamic data and requests are made. Constructed using `config`.

-}
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


{-| Constructor for a Config.

    articleApi : Request.Config Article () String
    articleApi =
        Request.config
            { decoder = articleDecoder
            , encoder = encodeArticle
            , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
            , toSuffix = (\id -> "/" ++ id)
            , options = []
            }

-}
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


{-| Create an option, to be passed into `config`, specifying which HTTP headers should be added in requests.
`"Accept: application/json"` is included by default.

    articleApi : Request.Config Article () String
    articleApi =
        Request.config
            { decoder = articleDecoder
            , encoder = encodeArticle
            , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
            , toSuffix = (\id -> "/" ++ id)
            , options =
              [ Request.header "Max-Forwards" "10"
              ]
            }

-}
header : String -> String -> ConfigOption
header field value =
    Header ( field, value )


{-| Create an option, to be passed into `config`, to make updates to a resource using the `PATCH` verb.
`PUT` is used for updates by default.

    articleApi : Request.Config Article () String
    articleApi =
        Request.config
            { decoder = articleDecoder
            , encoder = encodeArticle
            , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
            , toSuffix = (\id -> "/" ++ id)
            , options =
              [ Request.usePatchForUpdate
              ]
            }

-}
usePatchForUpdate : ConfigOption
usePatchForUpdate =
    UsePatchForUpdate


{-| Trigger a HTTP `GET` request, which, if successful, returns a `msg` parameterized with a `List` of all `resource`s.

    case msg of
        GetAllRequest ->
            ( model, Request.getAll articleApi () GetAllResponse )

-}
getAll : Config resource urlBaseData urlSuffixData -> urlBaseData -> (Result Error (List resource) -> msg) -> Cmd msg
getAll api urlBaseData responseMsg =
    request
        (verbToString Get)
        api.headers
        (api.toBaseUrl urlBaseData)
        Http.emptyBody
        (Http.expectJson (Decode.list api.decoder))
        |> Http.send responseMsg


{-| Trigger a HTTP `POST` request, which, if successful, returns a `msg` parameterized with the created `resource`.

    case msg of
        CreateRequest newArticle ->
            ( model, Request.create articleApi newArticle () CreateResponse )

-}
create : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> (Result Error resource -> msg) -> Cmd msg
create api resource urlBaseData responseMsg =
    request
        (verbToString Post)
        api.headers
        (api.toBaseUrl urlBaseData)
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


{-| Trigger a HTTP `PUT` or `PATCH` request, which, if successful, returns a `msg` parameterized with the updated `resource`
`PUT` is used by default. `PATCH` can be used by passing the result of `usePatchForUpdate` into `config`.

    case msg of
        UpdateRequest article ->
            ( model, Request.update articleApi article () article.id UpdateResponse )

-}
update : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> urlSuffixData -> (Result Error resource -> msg) -> Cmd msg
update api resource urlBaseData urlSuffixData responseMsg =
    request
        (verbToString api.updateVerb)
        api.headers
        ((api.toBaseUrl urlBaseData) ++ (api.toSuffix urlSuffixData))
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


{-| Trigger a HTTP `DELETE` request, which, if successful, returns a `msg` parameterized with the deleted `resource`.

    case msg of
        DeleteRequest article ->
            ( model, Request.delete articleApi article () article.id DeleteResponse )

-}
delete : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> urlSuffixData -> (Result Error resource -> msg) -> Cmd msg
delete api resource urlBaseData urlSuffixData responseMsg =
    request
        (verbToString Delete)
        api.headers
        ((api.toBaseUrl urlBaseData) ++ (api.toSuffix urlSuffixData))
        (Http.jsonBody <| api.encoder resource)
        (Http.expectJson api.decoder)
        |> Http.send responseMsg


request : String -> List ( String, String ) -> String -> Http.Body -> Http.Expect a -> Http.Request a
request verb headers url body expect =
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
