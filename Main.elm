module Main exposing (..)

import JsonApi
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Todo exposing (Todo, todoDecoder, encodeTodo)


type alias Model =
    { todos : JsonApi.Collection Todo
    }


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = JsonApiMsg (JsonApi.Msg Todo)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsonApiMsg apiMsg ->
            let
                ( updatedTodos, newCmd ) =
                    JsonApi.update apiMsg model.todos
            in
                ( { model | todos = updatedTodos }, Cmd.map JsonApiMsg newCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : ( Model, Cmd Msg )
init =
    let
        urls =
            { getIndex = "http://todo-backend-sinatra.herokuapp.com/todos"
            , post = "http://todo-backend-sinatra.herokuapp.com/todos"
            , put = "http://todo-backend-sinatra.herokuapp.com/todos/:uid"
            , delete = "http://todo-backend-sinatra.herokuapp.com/todos/:uid"
            }

        initialModel =
            { todos = JsonApi.initCollection todoDecoder encodeTodo .uid urls }
    in
        update (JsonApiMsg <| JsonApi.GetIndex []) initialModel


newTodo : Todo
newTodo =
    { uid = ""
    , title = "Blah!"
    , order = 0
    , completed = False
    }


todoView : Todo -> Html Msg
todoView todo =
    div []
        [ text todo.title
        , Html.button
            [ onClick
                (JsonApiMsg <|
                    JsonApi.Put todo
                        [ ( ":uid", todo.uid ) ]
                )
            ]
            [ text "Update" ]
        , Html.button
            [ onClick
                (JsonApiMsg <|
                    JsonApi.Delete todo
                        [ ( ":uid", todo.uid ) ]
                )
            ]
            [ text "Delete" ]
        ]


view : Model -> Html Msg
view model =
    div [] <|
        [ Html.button [ onClick (JsonApiMsg <| JsonApi.GetIndex []) ] [ text "Load Todos" ]
        , Html.button [ onClick (JsonApiMsg <| JsonApi.Post newTodo []) ] [ text "Save New Todo" ]
        ]
            ++ (List.map todoView model.todos.resources)
