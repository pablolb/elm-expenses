port module EditTransaction exposing (Input, Msg(..), Results, State, emptyState, update, validateForm, viewForm)

import Date exposing (Date)
import Html exposing (Html, button, div, form, input, label, option, p, select, span, text)
import Html.Attributes exposing (attribute, class, classList, lang, name, placeholder, selected, step, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import List.Extra
import Maybe exposing (withDefault)
import Misc exposing (cyAttr, isError, isFieldNotBlank, keepError)
import Settings exposing (Settings, defaultSettings)
import Transactions exposing (Entry, JsonTransaction, Transaction, transactionToJson)


type alias State =
    { input : Input
    , results : Maybe Results
    , settings : Settings
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
    , settings = defaultSettings
    }


type Msg
    = EditDate String
    | EditDescription String
    | EditDestination String
    | EditSource String
    | EditAmount String
    | SubmitForm
    | DeleteTransaction String String
    | Close


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
                f =
                    model.input

                input =
                    { f | description = description }
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
            ( { model | results = results }, cmd, close )

        DeleteTransaction id version ->
            ( model, deleteTransaction ( id, version ), True )

        Close ->
            ( model, Cmd.none, True )


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


viewForm : State -> Html Msg
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
    in
    div []
        [ form
            [ class "ui large form"
            , classList
                [ ( "error", isFormError )
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
            , viewFormValidation model.results
            , button [ class "positive ui button right floated", cyAttr "submit" ]
                [ text "Submit" ]
            , div [ class "ui button", onClick Close ]
                [ text "Cancel" ]
            , maybeViewDeleteButton f
            ]
        ]


maybeViewDeleteButton : Input -> Html Msg
maybeViewDeleteButton f =
    if f.id /= "" then
        div [ class "negative ui button", cyAttr "delete", onClick (DeleteTransaction f.id f.version) ]
            [ text "Delete" ]

    else
        span [] []


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



---- PORTS ELM => JS ----


port saveTransaction : JsonTransaction -> Cmd msg


port deleteTransaction : ( String, String ) -> Cmd msg
