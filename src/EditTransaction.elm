port module EditTransaction exposing
    ( EditMode(..)
    , FrequentDescription
    , FrequentDescriptions
    , Input
    , Msg(..)
    , Results
    , State
    , deleteCancelled
    , deleteConfirmed
    , emptyState
    , transactionDeleted
    , transactionDeletedError
    , transactionSaved
    , transactionSavedError
    , update
    , validateForm
    , viewForm
    )

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, button, div, form, i, input, label, option, p, select, span, text)
import Html.Attributes exposing (attribute, checked, class, classList, for, id, lang, list, name, placeholder, selected, step, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import List.Extra
import Maybe exposing (withDefault)
import Misc exposing (cyAttr, isError, isFieldNotBlank, keepError, viewConfirmModal, viewDataList)
import Settings exposing (Settings, defaultSettings)
import Transactions exposing (Entry, JsonTransaction, Transaction, transactionToJson)


type alias State =
    { input : Input
    , results : Maybe Results
    , editMode : EditMode
    , accounts : List String
    , descriptions : FrequentDescriptions
    , settings : Settings
    , saving : Bool
    }


type alias Input =
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


type alias Results =
    { date : Result String Date
    , description : Result String String
    , destination : Result String String
    , source : Result String String
    , amount : Result String Int
    , currency : Result String String
    }


type alias FrequentDescription =
    { description : String
    , destination : String
    , source : String
    , count : Int
    }


type alias FrequentDescriptions =
    Dict String FrequentDescription


emptyState : State
emptyState =
    { input =
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
    , results = Nothing
    , editMode = Simple
    , accounts = []
    , descriptions = Dict.empty
    , settings = defaultSettings
    , saving = False
    }


type EditMode
    = Simple
    | Advanced


type Msg
    = EditDate String
    | EditDescription String
    | EditDestination String
    | EditSource String
    | EditAmount String
    | EditCurrency String
    | SubmitForm
    | TransactionSaved (Result Json.Decode.Error Transaction)
    | TransactionSavedError (Result Json.Decode.Error String)
    | DeleteRequested
    | DeleteCancelled
    | DeleteConfirmed
    | TransactionDeleted
    | TransactionDeletedError (Result Json.Decode.Error String)
    | ToggleEditMode
    | Close
    | NoOp


update : Msg -> State -> ( State, Cmd Msg, Bool )
update msg model =
    case msg of
        EditDate date ->
            let
                f =
                    model.input

                input =
                    { f | date = date }
            in
            ( { model | input = input }, Cmd.none, False )

        EditDescription description ->
            let
                maybeDstSrc =
                    Dict.get description model.descriptions

                destination =
                    maybeDstSrc |> Maybe.map .destination |> withDefault f.destination

                source =
                    maybeDstSrc |> Maybe.map .source |> withDefault f.source

                extraDestinations =
                    if destination /= f.destination then
                        destination :: f.extraDestinations

                    else
                        f.extraDestinations

                extraSources =
                    if source /= f.source then
                        source :: f.extraSources

                    else
                        f.extraSources

                f =
                    model.input

                input =
                    { f
                        | description = description
                        , destination = destination
                        , source = source
                        , extraDestinations = extraDestinations
                        , extraSources = extraSources
                    }
            in
            ( { model | input = input }, Cmd.none, False )

        EditDestination destination ->
            let
                f =
                    model.input

                input =
                    { f | destination = destination }
            in
            ( { model | input = input }, Cmd.none, False )

        EditSource source ->
            let
                f =
                    model.input

                input =
                    { f | source = source }
            in
            ( { model | input = input }, Cmd.none, False )

        EditAmount amount ->
            let
                f =
                    model.input

                input =
                    { f | amount = amount }
            in
            ( { model | input = input }, Cmd.none, False )

        EditCurrency currency ->
            let
                f =
                    model.input

                input =
                    { f | currency = currency }
            in
            ( { model | input = input }, Cmd.none, False )

        SubmitForm ->
            let
                isValid : Result Results Transaction
                isValid =
                    validateForm model.input

                ( results, cmd, close ) =
                    case isValid of
                        Ok transaction ->
                            ( Nothing, transactionToJson transaction |> saveTransaction, True )

                        Err e ->
                            ( Just e, Cmd.none, False )
            in
            ( { model | results = results, saving = True }, cmd, close )

        TransactionSaved (Err _) ->
            ( { model | saving = False }, Cmd.none, False )

        TransactionSaved (Ok _) ->
            ( { model | saving = False }, Cmd.none, True )

        TransactionSavedError (Err _) ->
            ( { model | saving = False }, Cmd.none, False )

        TransactionSavedError (Ok _) ->
            ( { model | saving = False }, Cmd.none, False )

        ToggleEditMode ->
            let
                editMode =
                    if model.editMode == Simple then
                        Advanced

                    else
                        Simple
            in
            ( { model | editMode = editMode }, Cmd.none, False )

        DeleteRequested ->
            ( model, showDeleteModal (), False )

        DeleteCancelled ->
            ( model, Cmd.none, False )

        DeleteConfirmed ->
            ( model, deleteTransaction ( model.input.id, model.input.version ), True )

        TransactionDeleted ->
            ( model, Cmd.none, True )

        TransactionDeletedError _ ->
            ( model, Cmd.none, False )

        Close ->
            ( model, Cmd.none, True )

        NoOp ->
            ( model, Cmd.none, False )


validateForm : Input -> Result Results Transaction
validateForm input =
    let
        results : Results
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


viewForm : State -> ( Html Msg, List (Html Msg) )
viewForm model =
    let
        f : Input
        f =
            model.input

        isFormError =
            case model.results of
                Just _ ->
                    True

                _ ->
                    False

        isDateError =
            model.results
                |> Maybe.map (\results -> isError results.date)
                |> withDefault False

        isDescriptionError =
            model.results
                |> Maybe.map (\results -> isError results.description)
                |> withDefault False

        isDestinationError =
            model.results
                |> Maybe.map (\results -> isError results.destination)
                |> withDefault False

        isSourceError =
            model.results
                |> Maybe.map (\results -> isError results.source)
                |> withDefault False

        isAmountError =
            model.results
                |> Maybe.map (\results -> isError results.amount)
                |> withDefault False

        isCurrencyError =
            model.results
                |> Maybe.map (\results -> isError results.currency)
                |> withDefault False

        cmd =
            if model.saving then
                NoOp

            else
                SubmitForm
    in
    ( div []
        [ form
            [ class "ui large form"
            , classList
                [ ( "error", isFormError )
                ]
            , onSubmit cmd
            ]
            [ div [ class "field", classList [ ( "error", isDateError ) ] ]
                [ label [] [ text "Date" ]
                , input
                    [ name "date", cyAttr "date", type_ "date", value f.date, onInput EditDate ]
                    []
                ]
            , div [ class "field", classList [ ( "error", isDescriptionError ) ] ]
                [ label [] [ text "Description" ]
                , input [ name "description", cyAttr "description", list "descriptions", placeholder "Supermarket", value f.description, onInput EditDescription ] []
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
            , viewCurrencyInput model isCurrencyError
            , div [ class "field", classList [ ( "error", isDestinationError ) ] ]
                [ label [] [ text "Expense" ]
                , viewDestinationInput model
                ]
            , div [ class "field", classList [ ( "error", isSourceError ) ] ]
                [ label [] [ text "Source" ]
                , viewSourceInput model
                ]
            , viewFormValidation model.results
            , maybeViewDeleteButton f
            ]
        , viewAccountsDataList model
        , viewDescriptionsDataList model.descriptions
        , viewConfirmModal
        ]
    , [ div [ class "item" ]
            [ div [ class "ui button", onClick Close ]
                [ text "Cancel" ]
            ]
      , div [ class "right menu" ]
            [ div [ class "item" ]
                [ viewToggleEditModeButton model.editMode
                ]
            , div [ class "item", cyAttr "submit", onClick cmd ]
                [ button [ class "positive ui button right floated", classList [ ( "disabled", model.saving ) ] ]
                    [ text "Submit" ]
                ]
            ]
      ]
    )


viewDestinationInput : State -> Html Msg
viewDestinationInput model =
    case model.editMode of
        Simple ->
            select [ class "ui fluid dropdown", cyAttr "destination", name "destination", onInput EditDestination ] (destinationOptions model)

        Advanced ->
            input [ name "destination", cyAttr "destination", placeholder "Expenses:Groceries", list "accounts", value model.input.destination, onInput EditDestination ] []


viewSourceInput : State -> Html Msg
viewSourceInput model =
    case model.editMode of
        Simple ->
            select [ class "ui fluid dropdown", cyAttr "source", name "source", onInput EditSource ] (sourceOptions model)

        Advanced ->
            input [ name "source", cyAttr "source", placeholder "Assets:Cash", list "accounts", value model.input.source, onInput EditSource ] []


viewCurrencyInput : State -> Bool -> Html Msg
viewCurrencyInput model isCurrencyError =
    case model.editMode of
        Simple ->
            div [] []

        Advanced ->
            div [ class "field", classList [ ( "error", isCurrencyError ) ] ]
                [ label [] [ text "Currency" ]
                , input [ name "currency", cyAttr "currency", placeholder "USD", value model.input.currency, onInput EditCurrency ] []
                ]


maybeViewDeleteButton : Input -> Html Msg
maybeViewDeleteButton f =
    if f.id /= "" then
        div [ class "negative ui button", cyAttr "delete", onClick DeleteRequested ]
            [ text "Delete" ]

    else
        span [] []


viewToggleEditModeButton : EditMode -> Html Msg
viewToggleEditModeButton editMode =
    let
        isChecked =
            editMode == Advanced
    in
    div [ class "ui toggle checkbox" ]
        [ input [ id "toggle-advanced", type_ "checkbox", cyAttr "toggle-advanced", checked isChecked, onClick ToggleEditMode ] []
        , label [ for "toggle-advanced" ] [ text "Advanced Edit" ]
        ]


destinationOptions : State -> List (Html Msg)
destinationOptions model =
    let
        options : List String
        options =
            (model.settings.destinationAccounts ++ model.input.extraDestinations)
                |> List.Extra.unique

        selectedOpt : String
        selectedOpt =
            model.input.destination
    in
    options
        |> List.map (\opt -> option [ value opt, selected (selectedOpt == opt) ] [ text opt ])


sourceOptions : State -> List (Html Msg)
sourceOptions model =
    let
        options : List String
        options =
            (model.settings.sourceAccounts ++ model.input.extraSources)
                |> List.Extra.unique

        selectedOpt : String
        selectedOpt =
            model.input.source
    in
    options
        |> List.map (\opt -> option [ value opt, selected (selectedOpt == opt) ] [ text opt ])


viewFormValidation : Maybe Results -> Html Msg
viewFormValidation results =
    case results of
        Nothing ->
            div [] []

        Just res ->
            viewFormErrors res


viewFormErrors : Results -> Html Msg
viewFormErrors results =
    let
        dropSuccess : Result String a -> Result String String
        dropSuccess res =
            Result.map (\_ -> "") res

        formErrors : List String
        formErrors =
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


viewAccountsDataList : State -> Html Msg
viewAccountsDataList model =
    let
        accounts =
            model.settings.destinationAccounts
                ++ model.settings.sourceAccounts
                ++ List.sort model.accounts
    in
    viewDataList "accounts" accounts


viewDescriptionsDataList : FrequentDescriptions -> Html Msg
viewDescriptionsDataList descriptions =
    viewDataList "descriptions" (descriptions |> Dict.values |> List.sortBy .count |> List.reverse |> List.map .description)



---- PORTS ELM => JS ----


port saveTransaction : JsonTransaction -> Cmd msg


port deleteTransaction : ( String, String ) -> Cmd msg


port showDeleteModal : () -> Cmd msg



---- PORTS JS => ELM ----


port transactionSaved : (Json.Decode.Value -> msg) -> Sub msg


port transactionSavedError : (Json.Decode.Value -> msg) -> Sub msg


port transactionDeleted : (Json.Decode.Value -> msg) -> Sub msg


port transactionDeletedError : (Json.Decode.Value -> msg) -> Sub msg


port deleteCancelled : (Json.Decode.Value -> msg) -> Sub msg


port deleteConfirmed : (Json.Decode.Value -> msg) -> Sub msg
