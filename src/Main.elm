port module Main exposing (ListItem(..), Model, Msg(..), Page(..), defaultFormInput, initialModel, main, update, view)

import Browser
import Date exposing (Date)
import EditTransaction
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Html exposing (Html, button, div, form, h1, h2, i, input, label, node, option, p, pre, select, span, text, textarea)
import Html.Attributes exposing (attribute, class, classList, id, lang, list, name, placeholder, selected, step, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import List.Extra
import Maybe exposing (withDefault)
import Misc exposing (isError, isFieldNotBlank, keepError)
import Settings as EditSettings exposing (Msg(..), Settings, decodeSettings)
import Task
import Time exposing (Month(..))
import Transactions exposing (Entry, Transaction, decodeTransactions)



---- MODEL ----


type alias Model =
    { transactions : List Transaction
    , listItems : List ListItem
    , editTransactionState : EditTransaction.State
    , settings : Settings
    , editSettingsState : EditSettings.State
    , settingsStatus : SettingsStatus
    , currentDate : Date
    , currentPage : Page
    }


type ListItem
    = D Date
    | T Transaction


type Page
    = Welcome
    | List
    | Edit
    | EditSettings


type SettingsStatus
    = SettingsUnknown
    | NoSettings
    | SettingsLoaded



---- FORM STUFF ----


initialModel : Model
initialModel =
    { transactions = []
    , listItems = []
    , editTransactionState = EditTransaction.emptyState
    , settings = EditSettings.defaultSettings
    , editSettingsState = EditSettings.emptyState
    , settingsStatus = SettingsUnknown
    , currentDate = Date.fromCalendarDate 2024 Jan 1
    , currentPage = List
    }



---- UPDATE ----


type Msg
    = GotTransactions (Result Json.Decode.Error (List Transaction))
    | ReceiveDate Date
    | SetPage Page
    | EditTransaction Transaction
    | GotSettings (Result Json.Decode.Error Settings)
    | GotFirstRun
    | ImportSample
    | EditTransactionMsg EditTransaction.Msg
    | EditSettingsMsg EditSettings.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFirstRun ->
            let
                editSettingsState =
                    getSettingsFormInput model.settings
            in
            ( { model
                | settingsStatus = NoSettings
                , currentPage = Welcome
                , editSettingsState = { editSettingsState | showCancelButton = False }
              }
            , Cmd.none
            )

        ReceiveDate date ->
            ( { model | currentDate = date }, Cmd.none )

        SetPage Edit ->
            ( { model
                | currentPage = Edit
                , editTransactionState =
                    { input = defaultFormInput model
                    , results = Nothing
                    , settings = model.settings
                    }
              }
            , Cmd.none
            )

        SetPage EditSettings ->
            ( { model
                | currentPage = EditSettings
                , editSettingsState = getSettingsFormInput model.settings
              }
            , Cmd.none
            )

        SetPage page ->
            ( { model | currentPage = page }, Cmd.none )

        EditTransaction transaction ->
            let
                editTransactionState =
                    transactionFormInput transaction model.settings
            in
            ( { model | editTransactionState = editTransactionState, currentPage = Edit }, Cmd.none )

        EditTransactionMsg txnMsg ->
            let
                ( editTransactionState, cmd, close ) =
                    EditTransaction.update txnMsg model.editTransactionState

                page =
                    if close then
                        List

                    else
                        model.currentPage
            in
            ( { model
                | editTransactionState = editTransactionState
                , currentPage = page
              }
            , cmd |> Cmd.map EditTransactionMsg
            )

        EditSettingsMsg settingsMsg ->
            let
                ( editSettingsState, cmd, cancel ) =
                    EditSettings.update settingsMsg model.editSettingsState

                currentPage =
                    if cancel then
                        if settingsMsg == DeleteAllData then
                            Welcome

                        else
                            List

                    else
                        model.currentPage

                ( settings, settingsStatus, showCancelButton ) =
                    if settingsMsg == DeleteAllData then
                        ( EditSettings.defaultSettings, NoSettings, False )

                    else
                        ( model.settings, model.settingsStatus, editSettingsState.showCancelButton )
            in
            ( { model
                | editSettingsState = { editSettingsState | showCancelButton = showCancelButton }
                , currentPage = currentPage
                , settings = settings
                , settingsStatus = settingsStatus
              }
            , cmd |> Cmd.map EditSettingsMsg
            )

        GotTransactions (Ok transactions) ->
            let
                listItems =
                    buildListItems transactions
            in
            ( { model | transactions = transactions, listItems = listItems }, Cmd.none )

        ImportSample ->
            ( { model | currentPage = List }, EditSettings.importSampleData () )

        GotSettings (Ok settings) ->
            ( { model | settings = settings, settingsStatus = SettingsLoaded, currentPage = List }, Cmd.none )

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


cyAttr : String -> Html.Attribute Msg
cyAttr name =
    attribute "data-cy" name


view : Model -> Html Msg
view model =
    div [ class "ui container" ]
        [ renderPage model ]


renderPage : Model -> Html Msg
renderPage model =
    case model.currentPage of
        Welcome ->
            viewWelcome model

        List ->
            if List.isEmpty model.transactions then
                viewEmptyList

            else
                viewListItems model

        Edit ->
            EditTransaction.viewForm model.editTransactionState |> Html.map EditTransactionMsg

        EditSettings ->
            EditSettings.viewForm model.editSettingsState |> Html.map EditSettingsMsg


viewWelcome : Model -> Html Msg
viewWelcome model =
    div [ class "container" ]
        [ h2 [ class "ui icon header middle aligned" ]
            [ i [ class "money icon" ] []
            , div [ class "content" ] [ text "Welcome to Elm Expenses!" ]
            , div [ class "sub header" ] [ text "This is a work in progress" ]
            ]
        , EditSettings.viewForm model.editSettingsState |> Html.map EditSettingsMsg
        ]


viewEmptyList : Html Msg
viewEmptyList =
    div [ class "container" ]
        [ h2 [ class "ui icon header middle aligned" ]
            [ i [ class "money icon" ] []
            , div [ class "content" ] [ text "Welcome to Elm Expenses!" ]
            , div [ class "sub header" ] [ text "This is a work in progress" ]
            ]
        , div [ class "ui center aligned placeholder segment" ]
            [ button [ class "ui positive button", cyAttr "import-sample", onClick ImportSample ]
                [ text "Import Sample" ]
            , div [ class "ui horizontal divider" ] [ text "Or" ]
            , button [ class "blue ui button", cyAttr "add-transaction", onClick (SetPage Edit) ]
                [ text "Add Transaction" ]
            ]
        ]


viewListItems : Model -> Html Msg
viewListItems model =
    div [ class "ui celled list relaxed" ]
        (List.map
            (\item ->
                case item of
                    T transaction ->
                        viewTransaction transaction

                    D date ->
                        viewDate date
            )
            model.listItems
            ++ [ button [ class "massive circular ui blue icon button fab", cyAttr "add-transaction", onClick (SetPage Edit) ]
                    [ i [ class "plus icon" ] [] ]
               , button [ class "massive circular ui icon button fab-left", cyAttr "settings", onClick (SetPage EditSettings) ]
                    [ i [ class "settings icon" ] [] ]
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
    div [ class "item", onClick (EditTransaction txn) ]
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
        [ div [ class "header txn-description" ] [ text txn.description ]
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


defaultFormInput : Model -> EditTransaction.Input
defaultFormInput model =
    { id = ""
    , version = ""
    , date = Date.toIsoString model.currentDate
    , description = ""
    , destination = List.head model.settings.destinationAccounts |> Maybe.withDefault ""
    , source = List.head model.settings.sourceAccounts |> Maybe.withDefault ""
    , amount = ""
    , currency = model.settings.defaultCurrency
    , extraDestinations = []
    , extraSources = []
    }


transactionFormInput : Transaction -> Settings -> EditTransaction.State
transactionFormInput txn settings =
    { input =
        { id = txn.id
        , version = txn.version
        , date = Date.toIsoString txn.date
        , description = txn.description
        , destination = txn.destination.account
        , source = txn.source.account
        , amount = toFloat txn.destination.amount / 100.0 |> String.fromFloat
        , currency = txn.destination.currency
        , extraDestinations = [ txn.destination.account ]
        , extraSources = [ txn.source.account ]
        }
    , results = Nothing
    , settings = settings
    }


getSettingsFormInput : Settings -> EditSettings.State
getSettingsFormInput settings =
    { inputs =
        { version = settings.version
        , defaultCurrency = settings.defaultCurrency
        , destinationAccounts = String.join "\n" settings.destinationAccounts
        , sourceAccounts = String.join "\n" settings.sourceAccounts
        }
    , results = Nothing
    , showCancelButton = True
    }



---- PORTS JS => ELM ----


port gotFirstRun : (Json.Decode.Value -> msg) -> Sub msg


port gotTransactions : (Json.Decode.Value -> msg) -> Sub msg


port gotSettings : (Json.Decode.Value -> msg) -> Sub msg



---- PROGRAM ----


initialCmd : Cmd Msg
initialCmd =
    Date.today |> Task.perform ReceiveDate


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, initialCmd )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ gotTransactions (decodeTransactions >> GotTransactions)
        , gotSettings (decodeSettings >> GotSettings)
        , gotFirstRun (\_ -> GotFirstRun)
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
