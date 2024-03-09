port module Main exposing (Entry, FormInput, FormResult, FormValidation(..), ListItem(..), Model, Msg(..), Page(..), Transaction, defaultFormInput, initialModel, main, transactionDecoder, update, validateForm, view)

import Browser
import Date exposing (Date)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Html exposing (Html, button, div, form, h1, h2, i, input, label, node, option, p, pre, select, span, text, textarea)
import Html.Attributes exposing (attribute, class, classList, id, lang, list, name, placeholder, selected, step, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import List.Extra
import Maybe exposing (withDefault)
import Misc exposing (isError, isFieldNotBlank, keepError)
import Settings as EditSettings exposing (Msg(..), Settings, decodeSettings)
import Task
import Time exposing (Month(..))



---- MODEL ----


type alias Model =
    { transactions : List Transaction
    , listItems : List ListItem
    , formInput : FormInput
    , formValidation : FormValidation
    , settings : Settings
    , editSettingsState : EditSettings.State
    , settingsStatus : SettingsStatus
    , currentDate : Date
    , currentPage : Page
    }


type alias Transaction =
    { id : String
    , version : String
    , date : Date
    , description : String
    , destination : Entry
    , source : Entry
    }


type alias JsonTransaction =
    { id : String
    , version : String
    , date : String
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
    = Welcome
    | List
    | Edit
    | EditSettings


type SettingsStatus
    = SettingsUnknown
    | NoSettings
    | SettingsLoaded



---- FORM STUFF ----


type alias FormInput =
    { id : String
    , version : String
    , date : String
    , description : String
    , source : String
    , destination : String
    , currency : String
    , amount : String
    , extraDestinations : List String
    , extraSources : List String
    }


type alias FormResult =
    { date : Result String Date
    , description : Result String String
    , destination : Result String String
    , source : Result String String
    , amount : Result String Int
    , currency : Result String String
    }


type FormValidation
    = None
    | Error FormResult
    | Valid Transaction


emptyFormInput : FormInput
emptyFormInput =
    { id = ""
    , version = ""
    , date = ""
    , description = ""
    , source = ""
    , destination = ""
    , currency = ""
    , amount = ""
    , extraDestinations = []
    , extraSources = []
    }


initialModel : Model
initialModel =
    { transactions = []
    , listItems = []
    , formInput = emptyFormInput
    , formValidation = None
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
    | DeleteTransaction String String
    | EditDate String
    | EditDescription String
    | EditDestination String
    | EditSource String
    | EditAmount String
    | SubmitForm
    | GotSettings (Result Json.Decode.Error Settings)
    | GotFirstRun
    | ImportSample
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
                , formInput = defaultFormInput model
                , formValidation = None
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
                formInput =
                    transactionFormInput transaction
            in
            ( { model | formInput = formInput, formValidation = None, currentPage = Edit }, Cmd.none )

        DeleteTransaction id version ->
            ( { model | currentPage = List }, deleteTransaction ( id, version ) )

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

        SubmitForm ->
            let
                formValidation : FormValidation
                formValidation =
                    case validateForm model.formInput of
                        Ok transaction ->
                            Valid transaction

                        Err error ->
                            Error error

                cmd : Cmd Msg
                cmd =
                    case formValidation of
                        Valid transaction ->
                            transactionToJson transaction |> saveTransaction

                        _ ->
                            Cmd.none

                page : Page
                page =
                    case formValidation of
                        Valid _ ->
                            List

                        _ ->
                            Edit
            in
            ( { model | formValidation = formValidation, currentPage = page }, cmd )

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


validateForm : FormInput -> Result FormResult Transaction
validateForm input =
    let
        results : FormResult
        results =
            { date = Date.fromIsoString input.date
            , description = isFieldNotBlank "Description" input.description
            , destination = isFieldNotBlank "Destination" input.destination
            , source = isFieldNotBlank "Source" input.source
            , amount = isAmountValid input.amount
            , currency = isFieldNotBlank "Currency" input.currency
            }

        destination : Result String Entry
        destination =
            Result.map3
                Entry
                results.destination
                results.currency
                results.amount

        source : Result String Entry
        source =
            Result.map3
                Entry
                results.source
                results.currency
                (results.amount |> Result.map (\amnt -> amnt * -1))

        transaction : Result String Transaction
        transaction =
            Result.map4
                (Transaction input.id input.version)
                results.date
                results.description
                destination
                source
    in
    transaction |> Result.mapError (\_ -> results)


isAmountValid : String -> Result String Int
isAmountValid a =
    case String.toFloat a of
        Nothing ->
            Err ("Invalid amount: " ++ a)

        Just float ->
            if float == 0.0 then
                Err "Amount cannot be zero"

            else
                Ok (float * 100 |> round)



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
            viewForm model

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


viewForm : Model -> Html Msg
viewForm model =
    let
        f : FormInput
        f =
            model.formInput

        isFormError =
            case model.formValidation of
                Error _ ->
                    True

                _ ->
                    False

        isFormSuccess =
            case model.formValidation of
                Valid _ ->
                    True

                _ ->
                    False

        formResult : Maybe FormResult
        formResult =
            case model.formValidation of
                Error err ->
                    Just err

                _ ->
                    Nothing

        isDateError =
            formResult
                |> Maybe.map (\results -> isError results.date)
                |> withDefault False

        isDescriptionError =
            formResult
                |> Maybe.map (\results -> isError results.description)
                |> withDefault False

        isDestinationError =
            formResult
                |> Maybe.map (\results -> isError results.destination)
                |> withDefault False

        isSourceError =
            formResult
                |> Maybe.map (\results -> isError results.source)
                |> withDefault False

        isAmountError =
            formResult
                |> Maybe.map (\results -> isError results.amount)
                |> withDefault False
    in
    div []
        [ form
            [ class "ui large form"
            , classList
                [ ( "error", isFormError )
                , ( "success", isFormSuccess )
                ]
            , onSubmit SubmitForm
            ]
            [ div [ class "field", classList [ ( "error", isDateError ) ] ]
                [ label [] [ text "Date" ]
                , input
                    [ name "date", cyAttr "date", type_ "date", value f.date, onInput EditDate ]
                    []
                ]
            , div [ class "field", classList [ ( "error", isDescriptionError ) ] ]
                [ label [] [ text "Description" ]
                , input [ name "description", cyAttr "description", placeholder "Supermarket", value f.description, onInput EditDescription ] []
                ]
            , div [ class "field", classList [ ( "error", isDestinationError ) ] ]
                [ label [] [ text "Expense" ]
                , select [ class "ui fluid dropdown", cyAttr "destination", name "destination", onInput EditDestination ] (destinationOptions model)
                ]
            , div [ class "field", classList [ ( "error", isSourceError ) ] ]
                [ label [] [ text "Source" ]
                , select [ class "ui fluid dropdown", cyAttr "source", name "source", onInput EditSource ] (sourceOptions model)
                ]
            , div [ class "field", classList [ ( "error", isAmountError ) ] ]
                [ label [] [ text "Amount" ]
                , input
                    [ name "amount"
                    , cyAttr "amount"
                    , type_ "number"
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
            , viewFormValidationResult model
            , button [ class "positive ui button right floated", cyAttr "submit" ]
                [ text "Submit" ]
            , div [ class "ui button", onClick (SetPage List) ]
                [ text "Cancel" ]
            , maybeViewDeleteButton f
            ]
        ]


maybeViewDeleteButton : FormInput -> Html Msg
maybeViewDeleteButton f =
    if f.id /= "" then
        div [ class "negative ui button", cyAttr "delete", onClick (DeleteTransaction f.id f.version) ]
            [ text "Delete" ]

    else
        span [] []


defaultFormInput : Model -> FormInput
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


transactionFormInput : Transaction -> FormInput
transactionFormInput txn =
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


destinationOptions : Model -> List (Html Msg)
destinationOptions model =
    let
        options : List String
        options =
            (model.settings.destinationAccounts ++ model.formInput.extraDestinations)
                |> List.Extra.unique

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
            (model.settings.sourceAccounts ++ model.formInput.extraSources)
                |> List.Extra.unique

        selectedOpt : String
        selectedOpt =
            model.formInput.source
    in
    options
        |> List.map (\opt -> option [ value opt, selected (selectedOpt == opt) ] [ text opt ])


viewFormValidationResult : Model -> Html Msg
viewFormValidationResult model =
    case model.formValidation of
        Error _ ->
            viewFormErrors model

        Valid t ->
            viewFormSuccess t

        None ->
            div [] []


viewFormErrors : Model -> Html Msg
viewFormErrors model =
    let
        dropSuccess : Result String a -> Result String String
        dropSuccess res =
            Result.map (\_ -> "") res

        formResult : Maybe FormResult
        formResult =
            case model.formValidation of
                Error err ->
                    Just err

                _ ->
                    Nothing

        formErrors : List String
        formErrors =
            case formResult of
                Nothing ->
                    []

                Just results ->
                    [ results.date |> dropSuccess
                    , results.description
                    , results.destination
                    , results.source
                    , results.amount |> dropSuccess
                    , results.currency
                    ]
                        |> List.filterMap keepError
    in
    div [ class "ui error message" ]
        (div
            [ class "header" ]
            [ text "Invalid input" ]
            :: (formErrors |> List.map (\e -> p [] [ text e ]))
        )


viewFormSuccess : Transaction -> Html Msg
viewFormSuccess txn =
    div [ class "ui success message" ]
        [ div [ class "header" ] [ text "Data to be saved" ]
        , pre [] [ text (viewFormSucessText txn) ]
        ]


viewFormSucessText : Transaction -> String
viewFormSucessText txn =
    let
        entries =
            buildTextEntries [ txn.destination, txn.source ]

        rows : List String
        rows =
            (Date.toIsoString txn.date ++ "  " ++ txn.description)
                :: entries
    in
    String.join "\n" rows


buildTextEntries : List Entry -> List String
buildTextEntries entries =
    let
        findMax : List Int -> Int
        findMax nums =
            List.foldl max 0 nums

        parts =
            entries |> List.map (\e -> ( e.account, e.currency ++ " " ++ format usLocale (toFloat e.amount / 100.0) ))

        maxAccLength =
            parts |> List.map Tuple.first |> List.map String.length |> findMax

        maxAmntLength =
            parts |> List.map Tuple.second |> List.map String.length |> findMax

        padded =
            parts |> List.map (\( acc, amm ) -> [ String.padRight maxAccLength ' ' acc, String.padLeft maxAmntLength ' ' amm ])
    in
    List.map (String.join " ") padded


transactionToJson : Transaction -> JsonTransaction
transactionToJson txn =
    JsonTransaction txn.id txn.version (Date.toIsoString txn.date) txn.description txn.destination txn.source



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
        |> required "id" Json.Decode.string
        |> required "version" Json.Decode.string
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



---- PORTS ELM => JS ----


port saveTransaction : JsonTransaction -> Cmd msg


port deleteTransaction : ( String, String ) -> Cmd msg



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
