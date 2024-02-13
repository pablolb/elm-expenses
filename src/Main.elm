port module Main exposing (main)

import Browser
import Date exposing (Date)
import Dict exposing (Dict)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Maybe exposing (withDefault)



---- MODEL ----


type alias Model =
    { transactions : List Transaction
    , listItems : List ListItem
    }


type alias Transaction =
    { date : Date
    , description : String
    , destination : Entry
    , source : Entry
    }


type alias Entry =
    { account : String
    , currency : String
    , amount : Int
    }


type ListItem
    = D Date
    | T Transaction


initialModel : Model
initialModel =
    { transactions = []
    , listItems = []
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



---- UPDATE ----


type Msg
    = GotTransactions (Result Json.Decode.Error (List Transaction))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTransactions (Ok transactions) ->
            let
                listItems =
                    buildListItems transactions
            in
            ( { model | transactions = transactions, listItems = listItems }, Cmd.none )

        _ ->
            ( model, Cmd.none )


buildListItems : List Transaction -> List ListItem
buildListItems txns =
    let
        acc : Transaction -> Dict String (List ListItem) -> Dict String (List ListItem)
        acc txn dict =
            Dict.update (Date.toIsoString txn.date)
                (\exists ->
                    case exists of
                        Nothing ->
                            Just [ T txn ]

                        Just list ->
                            Just (T txn :: list)
                )
                dict

        groupedByDate : Dict String (List ListItem)
        groupedByDate =
            List.foldl acc Dict.empty txns

        byDate : List (List ListItem)
        byDate =
            Dict.toList groupedByDate
                |> List.sortBy Tuple.first
                |> List.reverse
                |> List.map Tuple.second

        listItems : List ListItem
        listItems =
            List.map
                (\items ->
                    case items of
                        (T t) :: _ ->
                            D t.date :: items

                        _ ->
                            items
                )
                byDate
                |> List.concat
    in
    listItems



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "ui container" ]
        [ viewListItems model.listItems
        ]


viewListItems : List ListItem -> Html Msg
viewListItems listItems =
    div [ class "ui celled list" ]
        (List.map
            (\item ->
                case item of
                    T transaction ->
                        viewTransaction transaction

                    D date ->
                        viewDate date
            )
            listItems
        )


viewDate : Date -> Html Msg
viewDate date =
    let
        dayOfWeek =
            Date.format "EEEE" date

        prettyDate =
            Date.format "d MMM y" date
    in
    div [ class "item date" ]
        [ div [ class "left floated content" ] [ text dayOfWeek ]
        , div [ class "right floated content" ] [ text prettyDate ]
        ]


viewTransaction : Transaction -> Html Msg
viewTransaction txn =
    div [ class "item" ]
        [ viewDescription txn
        , viewAmount txn.destination
        ]


viewDescription : Transaction -> Html Msg
viewDescription txn =
    let
        source =
            accountShortName txn.source.account

        destination =
            accountShortName txn.destination.account
    in
    div [ class "left floated content" ]
        [ div [] [ text txn.description ]
        , div [ class "description" ] [ text (source ++ " ↦ " ++ destination) ]
        ]


accountShortName : String -> String
accountShortName a =
    let
        parts =
            String.split ":" a |> List.reverse

        account =
            parts |> List.head |> withDefault a

        parents =
            parts |> List.tail |> withDefault [] |> List.reverse |> List.map (String.left 1)
    in
    if List.isEmpty parents then
        account

    else
        String.join ":" parents ++ ":" ++ account


viewAmount : Entry -> Html Msg
viewAmount entry =
    let
        amount =
            format usLocale (toFloat entry.amount / 100.0)
    in
    div [ class "right floated content" ] [ text (entry.currency ++ " " ++ amount) ]



---- DECODERS ----


entryDecoder : Json.Decode.Decoder Entry
entryDecoder =
    Json.Decode.succeed Entry
        |> required "account" Json.Decode.string
        |> required "currency" Json.Decode.string
        |> required "amount" Json.Decode.int


transactionDecoder : Json.Decode.Decoder Transaction
transactionDecoder =
    Json.Decode.succeed Transaction
        |> required "date" dateDecoder
        |> required "description" Json.Decode.string
        |> required "destination" entryDecoder
        |> required "source" entryDecoder


dateDecoder : Json.Decode.Decoder Date
dateDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                case Date.fromIsoString str of
                    Ok d ->
                        Json.Decode.succeed d

                    _ ->
                        Json.Decode.fail ("Invalid date " ++ str)
            )


decodeTransactions : Json.Decode.Value -> Result Json.Decode.Error (List Transaction)
decodeTransactions jsonData =
    Json.Decode.decodeValue (Json.Decode.list transactionDecoder) jsonData



---- PORTS JS => ELM ----


port gotTransactions : (Json.Decode.Value -> msg) -> Sub msg



---- PROGRAM ----


subscriptions : Model -> Sub Msg
subscriptions _ =
    gotTransactions (decodeTransactions >> GotTransactions)


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
