port module Main exposing (Entry, ListItem(..), Model, Msg(..), Transaction, initialModel, main, transactionDecoder, update, view)

import Browser
import Date exposing (Date)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Html exposing (Html, button, div, form, i, input, label, option, select, text)
import Html.Attributes exposing (attribute, class, lang, name, placeholder, selected, step, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import List.Extra
import Maybe exposing (withDefault)
import Task
import Time exposing (Month(..))



---- MODEL ----


type alias Model =
    { transactions : List Transaction
    , listItems : List ListItem
    , formInput : FormInput
    , settings : Settings
    , currentDate : Date
    , currentPage : Page
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


type Page
    = List
    | Edit


type alias Settings =
    { destinationAccounts : List String
    , sourceAccounts : List String
    , defaultCurrency : String
    }


defaultSettings : Settings
defaultSettings =
    { destinationAccounts = [ "Expenses:Groceries", "Expenses:Eat Out & Take Away" ]
    , sourceAccounts = [ "Assets:Cash", "Assets:Bank:Checking", "Liabilities:CreditCard" ]
    , defaultCurrency = "USD"
    }



---- FORM STUFF ----


type alias FormInput =
    { date : String
    , description : String
    , source : String
    , destination : String
    , currency : String
    , amount : String
    }


emptyFormInput : FormInput
emptyFormInput =
    { date = ""
    , description = ""
    , source = ""
    , destination = ""
    , currency = ""
    , amount = ""
    }


initialModel : Model
initialModel =
    { transactions = []
    , listItems = []
    , formInput = emptyFormInput
    , settings = defaultSettings
    , currentDate = Date.fromCalendarDate 2024 Jan 1
    , currentPage = List
    }



---- UPDATE ----


type Msg
    = GotTransactions (Result Json.Decode.Error (List Transaction))
    | ReceiveDate Date
    | SetPage Page
    | EditDate String
    | EditDescription String
    | EditDestination String
    | EditSource String
    | EditAmount String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveDate date ->
            ( { model | currentDate = date }, Cmd.none )

        SetPage Edit ->
            ( { model | currentPage = Edit, formInput = defaultFormInput model }, Cmd.none )

        SetPage page ->
            ( { model | currentPage = page }, Cmd.none )

        EditDate date ->
            let
                f =
                    model.formInput

                formInput =
                    { f | date = date }
            in
            ( { model | formInput = formInput }, Cmd.none )

        EditDescription description ->
            let
                f =
                    model.formInput

                formInput =
                    { f | description = description }
            in
            ( { model | formInput = formInput }, Cmd.none )

        EditDestination destination ->
            let
                f =
                    model.formInput

                formInput =
                    { f | destination = destination }
            in
            ( { model | formInput = formInput }, Cmd.none )

        EditSource source ->
            let
                f =
                    model.formInput

                formInput =
                    { f | source = source }
            in
            ( { model | formInput = formInput }, Cmd.none )

        EditAmount amount ->
            let
                f =
                    model.formInput

                formInput =
                    { f | amount = amount }
            in
            ( { model | formInput = formInput }, Cmd.none )

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
        grouped : List ( Transaction, List Transaction )
        grouped =
            txns
                |> List.sortWith
                    (\a b ->
                        case compare (Date.toIsoString b.date) (Date.toIsoString a.date) of
                            EQ ->
                                compare a.description b.description

                            LT ->
                                LT

                            GT ->
                                GT
                    )
                |> List.Extra.groupWhile (\a b -> a.date == b.date)

        listItems : List ListItem
        listItems =
            grouped
                |> List.map
                    (\nonEmptyList ->
                        let
                            ( head, tail ) =
                                nonEmptyList
                        in
                        D head.date
                            :: T head
                            :: List.map T tail
                    )
                |> List.concat
    in
    listItems



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "ui container" ]
        [ renderPage model ]


renderPage : Model -> Html Msg
renderPage model =
    case model.currentPage of
        List ->
            viewListItems model

        Edit ->
            viewForm model


viewListItems : Model -> Html Msg
viewListItems model =
    div [ class "ui celled list" ]
        (List.map
            (\item ->
                case item of
                    T transaction ->
                        viewTransaction transaction

                    D date ->
                        viewDate date
            )
            model.listItems
            ++ [ button [ class "massive circular ui blue icon button fab", onClick (SetPage Edit) ]
                    [ i [ class "plus icon" ] [] ]
               ]
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


viewForm : Model -> Html Msg
viewForm model =
    let
        f : FormInput
        f =
            model.formInput
    in
    div []
        [ form [ class "ui large form" ]
            [ div [ class "field" ]
                [ label [] [ text "Date" ]
                , input
                    [ name "date", type_ "date", value f.date, onInput EditDate ]
                    []
                ]
            , div [ class "field" ]
                [ label [] [ text "Description" ]
                , input [ name "description", placeholder "Supermarket", value f.description, onInput EditDescription ] []
                ]
            , div [ class "field" ]
                [ label [] [ text "Expense" ]
                , select [ class "ui fluid dropdown", value f.destination, onInput EditDestination ] (destinationOptions model)
                ]
            , div [ class "field" ]
                [ label [] [ text "Source" ]
                , select [ class "ui fluid dropdown", value f.source, onInput EditSource ] (sourceOptions model)
                ]
            , div [ class "field" ]
                [ label [] [ text "Amount" ]
                , input
                    [ type_ "number"
                    , step "0.01"
                    , placeholder "Amount"
                    , attribute "inputmode" "decimal"
                    , lang "en-US"
                    , placeholder "10.99"
                    , value f.amount
                    , onInput EditAmount
                    ]
                    []
                ]
            , div [ class "ui button", onClick (SetPage List) ]
                [ text "Cancel" ]
            , div [ class "blue ui button right floated" ]
                [ text "Submit" ]
            ]
        ]


defaultFormInput : Model -> FormInput
defaultFormInput model =
    { date = Date.toIsoString model.currentDate
    , description = ""
    , destination = List.head model.settings.destinationAccounts |> Maybe.withDefault ""
    , source = List.head model.settings.sourceAccounts |> Maybe.withDefault ""
    , amount = ""
    , currency = model.settings.defaultCurrency
    }


destinationOptions : Model -> List (Html Msg)
destinationOptions model =
    let
        options : List String
        options =
            model.settings.destinationAccounts

        selectedOpt : String
        selectedOpt =
            model.formInput.destination
    in
    options
        |> List.map (\opt -> option [ value opt, selected (selectedOpt == opt) ] [ text opt ])


sourceOptions : Model -> List (Html Msg)
sourceOptions model =
    let
        options : List String
        options =
            model.settings.sourceAccounts

        selectedOpt : String
        selectedOpt =
            model.formInput.source
    in
    options
        |> List.map (\opt -> option [ value opt, selected (selectedOpt == opt) ] [ text opt ])



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


initialCmd : Cmd Msg
initialCmd =
    Date.today |> Task.perform ReceiveDate


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, initialCmd )


subscriptions : Model -> Sub Msg
subscriptions _ =
    gotTransactions (decodeTransactions >> GotTransactions)


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
