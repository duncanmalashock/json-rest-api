module JsonRestApi.Request
    exposing
        ( Config
        , config
        , header
        , usePatchForUpdate
        , expectNoContentOnCreate
        , expectNoContentOnUpdate
        , expectNoContentOnDelete
        , getAll
        , create
        , update
        , delete
        )

{-| This module provides time-saving helpers for configuring and sending HTTP requests.

# Config
@docs Config, config

# Config Options
@docs header, usePatchForUpdate, expectNoContentOnCreate, expectNoContentOnUpdate, expectNoContentOnDelete

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
    , updateVerb : HttpVerb
    , headers : List ( String, String )
    , expectContent :
        { create : ResponseContent
        , update : ResponseContent
        , delete : ResponseContent
        }
    }


type RestOperation
    = RestGetAll
    | RestCreate
    | RestUpdate
    | RestDelete


type ConfigOption
    = Header ( String, String )
    | UsePatchForUpdate
    | ExpectNoContent RestOperation


type HttpVerb
    = HttpGet
    | HttpPost
    | HttpPut
    | HttpPatch
    | HttpDelete


type ResponseContent
    = JsonContent
    | NoContent


verbToString : HttpVerb -> String
verbToString verb =
    case verb of
        HttpGet ->
            "GET"

        HttpPost ->
            "POST"

        HttpPut ->
            "PUT"

        HttpPatch ->
            "PATCH"

        HttpDelete ->
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
            , updateVerb = HttpPut
            , headers = [ ( "Accept", "application/json" ) ]
            , expectContent =
                { create = JsonContent
                , update = JsonContent
                , delete = JsonContent
                }
            }
    in
        List.foldl applyOption newConfig configData.options


applyOption : ConfigOption -> Config resource urlBaseData urlSuffixData -> Config resource urlBaseData urlSuffixData
applyOption option config =
    case option of
        Header newHeader ->
            { config | headers = newHeader :: config.headers }

        UsePatchForUpdate ->
            { config | updateVerb = HttpPatch }

        ExpectNoContent restOperation ->
            let
                expectContent =
                    config.expectContent
            in
                case restOperation of
                    RestCreate ->
                        { config | expectContent = { expectContent | create = NoContent } }

                    RestUpdate ->
                        { config | expectContent = { expectContent | update = NoContent } }

                    RestDelete ->
                        { config | expectContent = { expectContent | delete = NoContent } }

                    _ ->
                        config


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


{-| Create an option, to be passed into `config`, to expect no content in the response to a resource create operation.

    articleApi : Request.Config Article () String
    articleApi =
        Request.config
            { decoder = articleDecoder
            , encoder = encodeArticle
            , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
            , toSuffix = (\id -> "/" ++ id)
            , options =
              [ Request.expectNoContentOnCreate
              ]
            }

-}
expectNoContentOnCreate : ConfigOption
expectNoContentOnCreate =
    ExpectNoContent RestCreate


{-| Create an option, to be passed into `config`, to expect no content in the response to a resource update operation.

    articleApi : Request.Config Article () String
    articleApi =
        Request.config
            { decoder = articleDecoder
            , encoder = encodeArticle
            , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
            , toSuffix = (\id -> "/" ++ id)
            , options =
              [ Request.expectNoContentOnUpdate
              ]
            }

-}
expectNoContentOnUpdate : ConfigOption
expectNoContentOnUpdate =
    ExpectNoContent RestUpdate


{-| Create an option, to be passed into `config`, to expect no content in the response to a resource delete operation.

    articleApi : Request.Config Article () String
    articleApi =
        Request.config
            { decoder = articleDecoder
            , encoder = encodeArticle
            , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
            , toSuffix = (\id -> "/" ++ id)
            , options =
              [ Request.expectNoContentOnDelete
              ]
            }

-}
expectNoContentOnDelete : ConfigOption
expectNoContentOnDelete =
    ExpectNoContent RestDelete


{-| Trigger a HTTP `GET` request, which, if successful, returns a `msg` parameterized with a `List` of all `resource`s.

    case msg of
        GetAllRequest ->
            ( model, Request.getAll articleApi () GetAllResponse )

-}
getAll : Config resource urlBaseData urlSuffixData -> urlBaseData -> (Result Error (List resource) -> msg) -> Cmd msg
getAll config urlBaseData responseMsg =
    request
        (verbToString HttpGet)
        config.headers
        (config.toBaseUrl urlBaseData)
        Http.emptyBody
        (Http.expectJson (Decode.list config.decoder))
        |> Http.send responseMsg


{-| Trigger a HTTP `POST` request, which, if successful, returns a `msg` parameterized with the created `resource`.

    case msg of
        CreateRequest newArticle ->
            ( model, Request.create articleApi newArticle () CreateResponse )

-}
create : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> (Result Error resource -> msg) -> Cmd msg
create config resource urlBaseData responseMsg =
    request
        (verbToString HttpPost)
        config.headers
        (config.toBaseUrl urlBaseData)
        (Http.jsonBody <| config.encoder resource)
        (expect RestCreate config resource)
        |> Http.send responseMsg


{-| Trigger a HTTP `PUT` or `PATCH` request, which, if successful, returns a `msg` parameterized with the updated `resource`
`PUT` is used by default. `PATCH` can be used by passing the result of `usePatchForUpdate` into `config`.

    case msg of
        UpdateRequest article ->
            ( model, Request.update articleApi article () article.id UpdateResponse )

-}
update : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> urlSuffixData -> (Result Error resource -> msg) -> Cmd msg
update config resource urlBaseData urlSuffixData responseMsg =
    request
        (verbToString config.updateVerb)
        config.headers
        ((config.toBaseUrl urlBaseData) ++ (config.toSuffix urlSuffixData))
        (Http.jsonBody <| config.encoder resource)
        (expect RestUpdate config resource)
        |> Http.send responseMsg


{-| Trigger a HTTP `DELETE` request, which, if successful, returns a `msg` parameterized with the deleted `resource`.

    case msg of
        DeleteRequest article ->
            ( model, Request.delete articleApi article () article.id DeleteResponse )

-}
delete : Config resource urlBaseData urlSuffixData -> resource -> urlBaseData -> urlSuffixData -> (Result Error resource -> msg) -> Cmd msg
delete config resource urlBaseData urlSuffixData responseMsg =
    request
        (verbToString HttpDelete)
        config.headers
        ((config.toBaseUrl urlBaseData) ++ (config.toSuffix urlSuffixData))
        (Http.jsonBody <| config.encoder resource)
        (expect RestDelete config resource)
        |> Http.send responseMsg


expect : RestOperation -> Config resource urlBaseData urlSuffixData -> resource -> Http.Expect resource
expect operation config resource =
    let
        jsonExpect =
            Http.expectJson config.decoder

        noContentExpect =
            Http.expectStringResponse (\_ -> Ok resource)
    in
        case operation of
            RestCreate ->
                case config.expectContent.create of
                    JsonContent ->
                        jsonExpect

                    NoContent ->
                        noContentExpect

            RestUpdate ->
                case config.expectContent.update of
                    JsonContent ->
                        jsonExpect

                    NoContent ->
                        noContentExpect

            RestDelete ->
                case config.expectContent.delete of
                    JsonContent ->
                        jsonExpect

                    NoContent ->
                        noContentExpect

            _ ->
                jsonExpect


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
