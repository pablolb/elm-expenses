module Misc exposing (..)

import Html exposing (Html, node, option)
import Html.Attributes exposing (attribute, id, value)


isFieldNotBlank : String -> String -> Result String String
isFieldNotBlank name value =
    let
        trimmed =
            String.trim value
    in
    if String.isEmpty trimmed then
        Err (name ++ " cannot be blank")

    else
        Ok trimmed


isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Nothing ->
            True

        _ ->
            False


isSomething : Maybe a -> Bool
isSomething m =
    case m of
        Nothing ->
            False

        _ ->
            True


isError : Result a b -> Bool
isError res =
    case res of
        Err _ ->
            True

        _ ->
            False


isOk : Result a b -> Bool
isOk res =
    case res of
        Err _ ->
            False

        _ ->
            True


keepError : Result String a -> Maybe String
keepError res =
    case res of
        Ok _ ->
            Nothing

        Err err ->
            Just err


cyAttr : String -> Html.Attribute msg
cyAttr name =
    attribute "data-cy" name


viewDataList : String -> List String -> Html msg
viewDataList nodeId list =
    node "datalist" [ id nodeId ] (List.map (\a -> option [ value a ] []) list)
