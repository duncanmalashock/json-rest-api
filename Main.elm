module Main exposing (..)

import ApiCollection exposing (Msg(..))
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Article exposing (Article, articleDecoder, encodeArticle)


type alias Model =
    { articles : ApiCollection.Model Article
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
    = ApiCollectionMsg (ApiCollection.Msg Article)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiCollectionMsg apiArticlesMsg ->
            let
                ( updatedArticles, newCmd ) =
                    ApiCollection.update apiArticlesMsg model.articles
            in
                ( { model | articles = updatedArticles }, Cmd.map ApiCollectionMsg newCmd )


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
                , put = "https://jsonplaceholder.typicode.com/posts/"
                , delete = "https://jsonplaceholder.typicode.com/posts/"
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
        , Html.button [ onClick (ApiCollectionMsg <| Put article) ] [ text "Update" ]
        , Html.button [ onClick (ApiCollectionMsg <| Delete article) ] [ text "Delete" ]
        ]


view : Model -> Html Msg
view model =
    div [] <|
        [ Html.button [ onClick (ApiCollectionMsg GetIndex) ] [ text "Load Articles" ]
        , Html.button [ onClick (ApiCollectionMsg (Post newArticle)) ] [ text "Save New Article" ]
        ]
            ++ (List.map articleView model.articles.collection)
