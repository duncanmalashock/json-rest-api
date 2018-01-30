module UrlSubstitution exposing (UrlSubstitutions, doUrlSubstitutions)

import Dict
import Regex


type alias UrlSubstitutions =
    List ( String, String )


urlSubstitutionRegex : Regex.Regex
urlSubstitutionRegex =
    Regex.regex ":[A-Za-z0-9_]+\\b"


doUrlSubstitutions : UrlSubstitutions -> String -> String
doUrlSubstitutions urlSubstitutions url =
    let
        dictionary =
            Dict.fromList urlSubstitutions
    in
        Regex.replace Regex.All
            urlSubstitutionRegex
            (\{ match } ->
                Dict.get match dictionary
                    |> Maybe.withDefault match
            )
            url
