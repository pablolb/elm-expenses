port module Main exposing (ListItem(..), Model, Msg(..), Page(..), defaultFormInput, initialModel, main, update, view)

import Browser
import Date exposing (Date)
import Dict exposing (Dict)
import EditTransaction exposing (FrequentDescription, FrequentDescriptions)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Html exposing (Html, button, div, h2, i, text)
import Html.Attributes exposing (attribute, class, name)
import Html.Events exposing (onClick)
import Json.Decode
import List.Extra
import Maybe exposing (withDefault)
import Settings as EditSettings exposing (Msg(..), Settings, decodeSettings)
import Task
import Time exposing (Month(..))
import Transactions exposing (Entry, Transaction, decodeTransactions, transactionDecoder)



---- MODEL ----


type alias Model =
    { transactions : List Transaction
    , accounts : Accounts
    , frequentDescriptions : EditTransaction.FrequentDescriptions
    , listItems : List ListItem
    , editTransactionState : EditTransaction.State
    , editSettingsState : EditSettings.State
    , settingsStatus : SettingsStatus
    , currentDate : Date
    , currentPage : Page
    }


type alias Account =
    { name : String
    , shortName : String
    }


type alias Accounts =
    Dict String Account


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
    , accounts = Dict.empty
    , frequentDescriptions = Dict.empty
    , listItems = []
    , editTransactionState = EditTransaction.emptyState
    , editSettingsState = EditSettings.emptyState
    , settingsStatus = SettingsUnknown
    , currentDate = Date.fromCalendarDate 2024 Jan 1
    , currentPage = Welcome
    }



---- UPDATE ----


type Msg
    = InitOk (Result Json.Decode.Error Settings)
    | InitError (Result Json.Decode.Error String)
    | InitSuccess
    | GotTransactions (Result Json.Decode.Error (List Transaction))
    | GotTransactionsError (Result Json.Decode.Error String)
    | ReceiveDate Date
    | SetPage Page
    | EditTransaction Transaction
    | GotFirstRun
    | ImportSample
    | ImportedSample
    | DeletedAllData
    | EditTransactionMsg EditTransaction.Msg
    | EditSettingsMsg EditSettings.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitOk (Ok settings) ->
            let
                s =
                    model.editSettingsState

                editSettingsState =
                    { s | settings = settings }
            in
            ( { model | editSettingsState = editSettingsState, settingsStatus = SettingsLoaded, currentPage = List }, getTransactions () )

        GotFirstRun ->
            let
                editSettingsState =
                    getSettingsFormInput model.editSettingsState
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
                    , editMode = EditTransaction.Simple
                    , accounts = Dict.keys model.accounts
                    , descriptions = model.frequentDescriptions
                    , settings = model.editSettingsState.settings
                    , saving = False
                    }
              }
            , Cmd.none
            )

        SetPage EditSettings ->
            ( { model
                | currentPage = EditSettings
                , editSettingsState = getSettingsFormInput model.editSettingsState
              }
            , Cmd.none
            )

        SetPage page ->
            ( { model | currentPage = page }, Cmd.none )

        EditTransaction transaction ->
            let
                editTransactionState =
                    transactionFormInput transaction model
            in
            ( { model | editTransactionState = editTransactionState, currentPage = Edit }, Cmd.none )

        EditTransactionMsg txnMsg ->
            let
                ( editTransactionState, cmd, close ) =
                    EditTransaction.update txnMsg model.editTransactionState

                ( page, ourCmd ) =
                    if close then
                        ( List, getTransactions () )

                    else
                        ( model.currentPage, Cmd.none )
            in
            ( { model
                | editTransactionState = editTransactionState
                , currentPage = page
              }
            , Cmd.batch [ cmd |> Cmd.map EditTransactionMsg, ourCmd ]
            )

        EditSettingsMsg settingsMsg ->
            let
                ( editSettingsState, cmd, cancel ) =
                    EditSettings.update settingsMsg model.editSettingsState

                currentPage =
                    if cancel then
                        if settingsMsg == DeleteAllConfirmed then
                            Welcome

                        else
                            List

                    else
                        model.currentPage

                ( transactions, listItems ) =
                    if settingsMsg == DeleteAllConfirmed then
                        ( [], [] )

                    else
                        ( model.transactions, model.listItems )

                ( accounts, frequentDescriptions ) =
                    if settingsMsg == DeleteAllConfirmed then
                        ( Dict.empty, Dict.empty )

                    else
                        ( model.accounts, model.frequentDescriptions )

                ( settingsStatus, showCancelButton ) =
                    if settingsMsg == DeleteAllConfirmed then
                        ( NoSettings, False )

                    else
                        ( model.settingsStatus, editSettingsState.showCancelButton )
            in
            ( { model
                | editSettingsState = { editSettingsState | showCancelButton = showCancelButton }
                , currentPage = currentPage
                , settingsStatus = settingsStatus
                , transactions = transactions
                , accounts = accounts
                , listItems = listItems
                , frequentDescriptions = frequentDescriptions
              }
            , cmd |> Cmd.map EditSettingsMsg
            )

        GotTransactions (Ok transactions) ->
            let
                listItems =
                    buildListItems transactions

                accounts =
                    buildAccounts transactions

                frequentDescriptions =
                    buildFrequentDescriptions transactions
            in
            ( { model
                | accounts = accounts
                , frequentDescriptions = frequentDescriptions
                , transactions = transactions
                , listItems = listItems
              }
            , Cmd.none
            )

        ImportSample ->
            ( { model | currentPage = List }, EditSettings.importSampleData () )

        ImportedSample ->
            ( model, getTransactions () )

        DeletedAllData ->
            ( initialModel, initialize () )

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


buildAccounts : List Transaction -> Accounts
buildAccounts txns =
    let
        accounts : Dict String Account
        accounts =
            txns
                |> List.map (\t -> [ t.source.account, t.destination.account ])
                |> List.concat
                |> List.Extra.unique
                |> List.map (\account -> ( account, Account account (accountShortName account) ))
                |> Dict.fromList
    in
    accounts


buildFrequentDescriptions : List Transaction -> FrequentDescriptions
buildFrequentDescriptions txns =
    let
        acc : ( String, { dst : String, src : String, cnt : Int } ) -> Dict String { dst : String, src : String, cnt : Int } -> Dict String { dst : String, src : String, cnt : Int }
        acc ( desc, rec ) dict =
            Dict.update desc
                (\exists ->
                    case exists of
                        Nothing ->
                            Just rec

                        Just current ->
                            Just { current | cnt = current.cnt + 1 }
                )
                dict
    in
    txns
        |> List.map (\t -> ( t.description, { dst = t.destination.account, src = t.source.account, cnt = 1 } ))
        |> List.foldl acc Dict.empty
        |> Dict.toList
        |> List.sortBy (\( _, rec ) -> rec.cnt)
        |> List.reverse
        |> List.take 50
        |> List.map (\( desc, rec ) -> ( desc, FrequentDescription desc rec.dst rec.src rec.cnt ))
        |> Dict.fromList



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
                        viewTransaction transaction model.accounts

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


viewTransaction : Transaction -> Accounts -> Html Msg
viewTransaction txn accounts =
    div [ class "item", onClick (EditTransaction txn) ]
        [ viewDescription txn accounts
        , viewAmount txn.destination
        ]


viewDescription : Transaction -> Accounts -> Html Msg
viewDescription txn accounts =
    let
        source =
            Dict.get txn.source.account accounts |> Maybe.map .shortName |> withDefault txn.source.account

        destination =
            Dict.get txn.destination.account accounts |> Maybe.map .shortName |> withDefault txn.destination.account
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
    , destination = List.head model.editSettingsState.settings.destinationAccounts |> Maybe.withDefault ""
    , source = List.head model.editSettingsState.settings.sourceAccounts |> Maybe.withDefault ""
    , amount = ""
    , currency = model.editSettingsState.settings.defaultCurrency
    , extraDestinations = []
    , extraSources = []
    }


transactionFormInput : Transaction -> Model -> EditTransaction.State
transactionFormInput txn model =
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
    , editMode = EditTransaction.Simple
    , accounts = Dict.keys model.accounts
    , descriptions = model.frequentDescriptions
    , settings = model.editSettingsState.settings
    , saving = False
    }


getSettingsFormInput : EditSettings.State -> EditSettings.State
getSettingsFormInput state =
    let
        settings =
            state.settings
    in
    { encryption = state.encryption
    , settings = settings
    , inputs =
        { version = settings.version
        , defaultCurrency = settings.defaultCurrency
        , destinationAccounts = String.join "\n" settings.destinationAccounts
        , sourceAccounts = String.join "\n" settings.sourceAccounts
        , currentPassword = ""
        , newPassword = ""
        , newPasswordConfirm = ""
        }
    , results = Nothing
    , showCancelButton = True
    , saving = False
    }



---- PORTS ELM => JS ----


port initialize : () -> Cmd msg


port getTransactions : () -> Cmd msg



---- PORTS JS => ELM ----


port gotFirstRun : (Json.Decode.Value -> msg) -> Sub msg


port gotTransactions : (Json.Decode.Value -> msg) -> Sub msg


port gotTransactionsError : (Json.Decode.Value -> msg) -> Sub msg


port gotInitOk : (Json.Decode.Value -> msg) -> Sub msg


port gotInitError : (Json.Decode.Value -> msg) -> Sub msg


port importedSampleData : (Json.Decode.Value -> msg) -> Sub msg


port deletedAllData : (Json.Decode.Value -> msg) -> Sub msg



---- PROGRAM ----


initialCmd : Cmd Msg
initialCmd =
    Cmd.batch
        [ initialize ()
        , Date.today |> Task.perform ReceiveDate
        ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, initialCmd )


stringDecoder : Json.Decode.Value -> Result Json.Decode.Error String
stringDecoder =
    Json.Decode.decodeValue Json.Decode.string


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ gotTransactions (decodeTransactions >> GotTransactions)
        , gotInitOk (decodeSettings >> InitOk)
        , gotInitError (stringDecoder >> InitError)
        , gotFirstRun (\_ -> GotFirstRun)
        , gotTransactionsError (stringDecoder >> GotTransactionsError)
        , importedSampleData (\_ -> ImportedSample)
        , deletedAllData (\_ -> DeletedAllData)
        , Sub.map EditTransactionMsg (EditTransaction.transactionSaved (Json.Decode.decodeValue transactionDecoder >> EditTransaction.TransactionSaved))
        , Sub.map EditTransactionMsg (EditTransaction.transactionSavedError (stringDecoder >> EditTransaction.TransactionSavedError))
        , Sub.map EditTransactionMsg (EditTransaction.transactionDeleted (\_ -> EditTransaction.TransactionDeleted))
        , Sub.map EditTransactionMsg (EditTransaction.transactionDeletedError (stringDecoder >> EditTransaction.TransactionDeletedError))
        , Sub.map EditTransactionMsg (EditTransaction.deleteCancelled (\_ -> EditTransaction.DeleteCancelled))
        , Sub.map EditTransactionMsg (EditTransaction.deleteConfirmed (\_ -> EditTransaction.DeleteConfirmed))
        , Sub.map EditSettingsMsg (EditSettings.deleteAllCancelled (\_ -> EditSettings.DeleteAllCancelled))
        , Sub.map EditSettingsMsg (EditSettings.deleteAllConfirmed (\_ -> EditSettings.DeleteAllConfirmed))
        , Sub.map EditSettingsMsg (EditSettings.settingsSaved (decodeSettings >> EditSettings.SettingsSaved))
        , Sub.map EditSettingsMsg (EditSettings.settingsSavedError (stringDecoder >> EditSettings.SettingsSavedError))
        , Sub.map EditSettingsMsg (EditSettings.gotEncryptedSettings (\_ -> EditSettings.GotEncryptedSettings))
        , Sub.map EditSettingsMsg (EditSettings.decryptedSettingsError (\_ -> EditSettings.GotDecryptionError))
        , Sub.map EditSettingsMsg (EditSettings.decryptedSettings (stringDecoder >> EditSettings.GotDecryptionSuccess))
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
