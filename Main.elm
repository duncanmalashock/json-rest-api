module Main exposing (..)

import JsonApi
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Article exposing (Article, articleDecoder, encodeArticle)


type alias Model =
    { articles : JsonApi.Collection Article
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
    = JsonApiMsg (JsonApi.Msg Article)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsonApiMsg apiMsg ->
            let
                ( updatedArticles, newCmd ) =
                    JsonApi.update apiMsg model.articles
            in
                ( { model | articles = updatedArticles }, Cmd.map JsonApiMsg newCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : ( Model, Cmd Msg )
init =
    ( { articles =
            { collection = []
            , error = Nothing
            , decoder = articleDecoder
            , encoder = encodeArticle
            , idAccessor = .id
            , urls =
                { getIndex = "https://jsonplaceholder.typicode.com/posts"
                , post = "https://jsonplaceholder.typicode.com/posts"
                , put = "https://jsonplaceholder.typicode.com/posts/:id"
                , delete = "https://jsonplaceholder.typicode.com/posts/:id"
                }
            }
      }
    , Cmd.none
    )


newArticle : Article
newArticle =
    { id = -1
    , title = "Blah!"
    , body = "Lorem ipsum"
    , userId = 0
    }


articleView : Article -> Html Msg
articleView article =
    div []
        [ text article.title
        , Html.button [ onClick (JsonApiMsg <| JsonApi.Put article [ ( ":id", toString article.id ) ]) ] [ text "Update" ]
        , Html.button [ onClick (JsonApiMsg <| JsonApi.Delete article [ ( ":id", toString article.id ) ]) ] [ text "Delete" ]
        ]


view : Model -> Html Msg
view model =
    div [] <|
        [ Html.button [ onClick (JsonApiMsg <| JsonApi.GetIndex []) ] [ text "Load Articles" ]
        , Html.button [ onClick (JsonApiMsg <| JsonApi.Post newArticle []) ] [ text "Save New Article" ]
        ]
            ++ (List.map articleView model.articles.collection)
