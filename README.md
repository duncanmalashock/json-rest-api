# json-rest-api
It often happens that an Elm application needs to implement CRUD operations through a JSON REST API. The HTTP requests and list manipulation involved in this communication can tend to be very similar, and writing the resulting boilerplate code, while not overly difficult, can still be time-consuming. This package attempts to help out.

**json-rest-api** provides two modules of simple helper functions:

- `Request` - for constructing URLS, encoding resources as JSON, and sending HTTP requests.
- `Response` - for handling responses, decoding resources, and updating a `List` of resources.

## Usage
1. Define a collection of resources in your `Model` as a `RemoteData Http.Error`:

```
type alias Model =
    { articles : RemoteData Http.Error (List Article)
    }
```

2. Define a `Config resource urlBaseData urlSuffixData` for the API you're going to use, including:
    - A `Decoder` for your type
    - An `encode` function for your type
    - A `toBaseUrl` for creating the URL to be requested (for GET requests for all resources and POST requests for creating) from your `urlBaseData` type
    - A `toSuffix` for creating the URL suffix (used for PUT/PATCH and DELETE requests for specific resources) from your `urlSuffixData` type (usually just the ID type of your resource)
    - A `List` of options—currently this package supports options for:
      - Adding request headers
      - Using the PATCH verb instead of the default PUT for updating a resource

```
import JsonRestApi.Request as Request
import JsonRestApi.Response as Response

articleApi : Request.Config Article () String
articleApi =
    Request.config
        { decoder = articleDecoder
        , encoder = encodeArticle
        , toBaseUrl = (\_ -> "http://www.example-api.com/articles")
        , toSuffix = (\id -> "/" ++ id)
        , options = []
        }
```

3. Make HTTP requests by calling the `Request` helper functions in your application's `update`, passing:
    - The `Config`
    - The `urlBaseData`, a `()` if your base URL is static
    - When necessary, a `resource` and `urlData` (data for creating the URL suffix)
    - A `Msg` to be sent when the response arrives

```
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetAllRequest ->
            ( model, Request.getAll articleApi () GetAllResponse )

        CreateRequest article ->
            ( model, Request.create articleApi article () CreateResponse )

        UpdateRequest article ->
            ( model, Request.update articleApi article () article.id UpdateResponse )

        DeleteRequest article ->
            ( model, Request.delete articleApi article () article.id DeleteResponse )
...
```

4. Update the `List` of resources in your `Model` by calling the `Response` helper functions in the response `Msg`s, passing:
    - The `Result`
    - The collection of resources
    - When updating or deleting, an equality test function for comparing two resources (i.e. by ID)

```
...
        GetAllResponse result ->
            ( { model | articles = Response.handleGetIndexResponse result model.articles }, Cmd.none )

        CreateResponse result ->
            ( { model | articles = Response.handleCreateResponse result model.articles }, Cmd.none )

        UpdateResponse result ->
            ( { model | articles = Response.handleUpdateResponse result articlesEqual model.articles }, Cmd.none )

        DeleteResponse result ->
            ( { model | articles = Response.handleDeleteResponse result articlesEqual model.articles }, Cmd.none )
```
