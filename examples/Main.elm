module Main exposing (..)

import Todo exposing (Todo, todoDecoder, encodeTodo)
import JsonApi.Request as Request
import JsonApi.Response as Response
import RemoteData exposing (RemoteData(..))
import Http exposing (Error)
import Html exposing (Html, div, span, text)
import Html.Attributes
import Html.Events exposing (onClick)


type alias Model =
    { todos : RemoteData Error (List Todo)
    }


todoApi : Request.Config Todo String
todoApi =
    Request.initConfig
        { decoder = todoDecoder
        , encoder = encodeTodo
        , baseUrl = "http://todo-backend-sinatra.herokuapp.com/todos"
        , toSuffix = (\id -> "/" ++ id)
        }
        |> Request.usePatchForUpdate


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = GetAllRequest
    | CreateRequest Todo
    | UpdateRequest Todo
    | DeleteRequest Todo
    | GetAllResponse (Result Error (List Todo))
    | CreateResponse (Result Error Todo)
    | UpdateResponse (Result Error Todo)
    | DeleteResponse (Result Error Todo)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetAllRequest ->
            ( model, Request.getAll todoApi GetAllResponse )

        CreateRequest todo ->
            ( model, Request.create todoApi newTodo CreateResponse )

        UpdateRequest todo ->
            ( model, Request.update todoApi todo todo.uid UpdateResponse )

        DeleteRequest todo ->
            ( model, Request.delete todoApi todo todo.uid DeleteResponse )

        GetAllResponse result ->
            ( { model | todos = Response.handleGetIndexResponse result model.todos }, Cmd.none )

        CreateResponse result ->
            ( { model | todos = Response.handleCreateResponse result model.todos }, Cmd.none )

        UpdateResponse result ->
            ( { model | todos = Response.handleUpdateResponse result todosEqual model.todos }, Cmd.none )

        DeleteResponse result ->
            ( { model | todos = Response.handleDeleteResponse result todosEqual model.todos }, Cmd.none )


todosEqual : Todo -> Todo -> Bool
todosEqual todo todo2 =
    todo.uid == todo2.uid


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : ( Model, Cmd Msg )
init =
    let
        initialModel =
            { todos = NotAsked
            }
    in
        ( initialModel, Request.getAll todoApi GetAllResponse )


newTodo : Todo
newTodo =
    { uid = ""
    , title = "Blah!"
    , order = 0
    , completed = False
    }


withCompleted : x -> { a | completed : x } -> { a | completed : x }
withCompleted newVal record =
    { record | completed = newVal }


todoView : Todo -> Html Msg
todoView todo =
    let
        attrs =
            case todo.completed of
                True ->
                    [ Html.Attributes.style
                        [ ( "textDecoration", "line-through" ) ]
                    ]

                False ->
                    []
    in
        div []
            [ span attrs
                [ text todo.title ]
            , Html.button
                [ onClick <| UpdateRequest (withCompleted True todo)
                ]
                [ text "Mark Completed" ]
            , Html.button
                [ onClick <| DeleteRequest todo
                ]
                [ text "Delete" ]
            ]


view : Model -> Html Msg
view model =
    div [] <|
        [ Html.button [ onClick <| CreateRequest newTodo ] [ text "Save New Todo" ]
        ]
            ++ (List.map todoView (RemoteData.withDefault [] model.todos))
