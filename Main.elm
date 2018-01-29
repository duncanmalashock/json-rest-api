module Main exposing (..)

import ApiArticles exposing (Msg(..))
import Article exposing (Article)
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type alias Model =
    { apiArticles : ApiArticles.Model
    }


type alias IdRecord =
    { id : Int
    }


idRecordDecoder : Decoder IdRecord
idRecordDecoder =
    Pipeline.decode IdRecord
        |> Pipeline.required "id" Decode.int


emptyDecoder : Decoder {}
emptyDecoder =
    Pipeline.decode {}


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = ApiArticlesMsg ApiArticles.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiArticlesMsg apiArticlesMsg ->
            let
                ( newApiArticles, newCmd ) =
                    ApiArticles.update apiArticlesMsg model.apiArticles
            in
                ( { model | apiArticles = newApiArticles }, Cmd.map ApiArticlesMsg newCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : ( Model, Cmd Msg )
init =
    ( { apiArticles =
            { articles = []
            , error = Nothing
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
        , Html.button [ onClick (ApiArticlesMsg <| PutArticle article) ] [ text "Update" ]
        , Html.button [ onClick (ApiArticlesMsg <| DeleteArticle article) ] [ text "Delete" ]
        ]


view : Model -> Html Msg
view model =
    div [] <|
        [ Html.button [ onClick (ApiArticlesMsg GetArticleIndex) ] [ text "Load Articles" ]
        , Html.button [ onClick (ApiArticlesMsg (PostArticle newArticle)) ] [ text "Save New Article" ]
        ]
            ++ (List.map articleView model.apiArticles.articles)
