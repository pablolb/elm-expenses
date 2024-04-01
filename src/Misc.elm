module Misc exposing (..)

import Html exposing (Html, div, i, node, option, p, text)
import Html.Attributes exposing (attribute, class, id, value)
import Html.Events exposing (onClick)


type MainNotification
    = MainNotification NotificationData


type PopupNotification
    = PopupNotification NotificationData


type Notification
    = Notification MainNotification
    | Popup PopupNotification


type NotificationType
    = NormalNotification
    | NegativeMessage
    | PositiveMessage


type alias NotificationData =
    { type_ : NotificationType
    , header : Maybe String
    , message : String
    }


viewNotification : Notification -> msg -> Html msg
viewNotification notification onClose =
    let
        ( messageClass, data ) =
            case notification of
                Notification (MainNotification notificationData) ->
                    ( "attached message", notificationData )

                Popup (PopupNotification notificationData) ->
                    ( "message", notificationData )

        typeClass =
            case data.type_ of
                NegativeMessage ->
                    "negative"

                PositiveMessage ->
                    "positive"

                NormalNotification ->
                    ""

        mainClass =
            "ui " ++ typeClass ++ " " ++ messageClass

        header =
            case data.header of
                Just txt ->
                    div [ class "header" ] [ text txt ]

                Nothing ->
                    div [] []
    in
    div [ class mainClass ]
        [ i [ class "close icon", onClick onClose ] []
        , header
        , p [] [ text data.message ]
        ]


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


dropSuccess : Result String a -> Result String String
dropSuccess res =
    Result.map (\_ -> "") res


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


viewConfirmModal : Html msg
viewConfirmModal =
    div [ class "ui mini modal" ]
        [ div [ class "content" ]
            [ p [] [ text "Are you sure?" ]
            ]
        , div [ class "actions" ]
            [ div [ class "ui red cancel inverted button", cyAttr "cancel-modal" ]
                [ i [ class "remove icon" ] []
                , text "No"
                ]
            , div [ class "ui green ok inverted button", cyAttr "confirm-modal" ]
                [ i [ class "checkmark icon" ] []
                , text "Yes"
                ]
            ]
        ]
