port module Settings exposing (Msg(..), Settings, State, cancelDeleteAll, confirmDeleteAll, decodeSettings, defaultSettings, emptyState, importSampleData, update, viewForm)

import Html exposing (Html, div, form, input, label, p, text, textarea)
import Html.Attributes exposing (class, classList, name, placeholder, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Misc exposing (cyAttr, isFieldNotBlank, keepError, viewConfirmModal)


type alias Settings =
    { version : String
    , destinationAccounts : List String
    , sourceAccounts : List String
    , defaultCurrency : String
    }


type ValidSettings
    = ValidSettings Settings


type alias State =
    { inputs : Inputs
    , results : Maybe Results
    , showCancelButton : Bool
    }


type alias Inputs =
    { version : String
    , defaultCurrency : String
    , destinationAccounts : String
    , sourceAccounts : String
    }


type alias Results =
    { defaultCurrency : Result String String
    , destinationAccounts : Result String String
    , sourceAccounts : Result String String
    }


type Msg
    = EditDefaultCurrency String
    | EditDestinationAccounts String
    | EditSourceAccounts String
    | Cancel
    | SubmitForm
    | ImportSample
    | DeleteAllRequested
    | DeleteAllCancelled
    | DeleteAllConfirmed


emptyState : State
emptyState =
    { inputs =
        { version = ""
        , defaultCurrency = ""
        , destinationAccounts = ""
        , sourceAccounts = ""
        }
    , results = Nothing
    , showCancelButton = False
    }


defaultSettings : Settings
defaultSettings =
    { version = ""
    , destinationAccounts = [ "Expenses:Groceries", "Expenses:Eat Out & Take Away" ]
    , sourceAccounts = [ "Assets:Cash", "Assets:Bank:Checking", "Liabilities:CreditCard" ]
    , defaultCurrency = "USD"
    }


update : Msg -> State -> ( State, Cmd Msg, Bool )
update msg model =
    case msg of
        EditDefaultCurrency currency ->
            let
                f =
                    model.inputs

                inputs =
                    { f | defaultCurrency = currency }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditDestinationAccounts accounts ->
            let
                f =
                    model.inputs

                inputs =
                    { f | destinationAccounts = accounts }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditSourceAccounts accounts ->
            let
                f =
                    model.inputs

                inputs =
                    { f | sourceAccounts = accounts }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        Cancel ->
            ( model, Cmd.none, True )

        SubmitForm ->
            let
                isValid =
                    validateForm model.inputs

                ( results, cmd, close ) =
                    case isValid of
                        Err e ->
                            ( Just e, Cmd.none, False )

                        Ok (ValidSettings settings) ->
                            ( Nothing, saveSettings settings, True )
            in
            ( { model | results = results }, cmd, close )

        ImportSample ->
            ( model, importSampleData (), True )

        DeleteAllRequested ->
            ( model, showDeleteAllModal (), False )

        DeleteAllCancelled ->
            ( model, Cmd.none, False )

        DeleteAllConfirmed ->
            ( model, deleteAllData (), True )


viewForm : State -> Html Msg
viewForm model =
    let
        f =
            model.inputs

        otherButtons =
            if model.showCancelButton then
                [ div [ class "ui button", cyAttr "cancel", onClick Cancel ] [ text "Cancel" ]
                , div [ class "ui blue button", cyAttr "import-sample", onClick ImportSample ] [ text "Import Sample" ]
                , div [ class "ui negative button", cyAttr "delete-all-data", onClick DeleteAllRequested ] [ text "Delete All Data" ]
                ]

            else
                []

        errors : List String
        errors =
            case model.results of
                Nothing ->
                    []

                Just res ->
                    [ res.defaultCurrency, res.destinationAccounts, res.sourceAccounts ]
                        |> List.filterMap keepError

        hadErrors =
            not (List.isEmpty errors)

        errorView =
            if hadErrors then
                viewFormErrors errors

            else
                div [] []
    in
    div []
        [ form [ class "ui large form", classList [ ( "error", hadErrors ) ], onSubmit SubmitForm ]
            ([ div [ class "field" ]
                [ label [] [ text "Default currency" ]
                , input [ name "defaultCurrency", cyAttr "default-currency", placeholder "USD", value f.defaultCurrency, onInput EditDefaultCurrency ] []
                ]
             , div [ class "field" ]
                [ label [] [ text "Expense accounts" ]
                , textarea [ name "destinationAccounts", cyAttr "destination-accounts", placeholder "Expenses:Groceries\nExpenses:Eat Out & Take Away", value f.destinationAccounts, onInput EditDestinationAccounts ] []
                ]
             , div [ class "field" ]
                [ label [] [ text "Source accounts" ]
                , textarea [ name "sourceAccounts", cyAttr "source-accounts", placeholder "Assets:Cash\nLiabilities:CreditCard", value f.sourceAccounts, onInput EditSourceAccounts ] []
                ]
             , errorView
             ]
                ++ otherButtons
                ++ [ div [ class "ui positive button right floated", cyAttr "save", onClick SubmitForm ]
                        [ text "Save" ]
                   ]
            )
        , viewConfirmModal
        ]


validateForm : Inputs -> Result Results ValidSettings
validateForm input =
    let
        results : Results
        results =
            { defaultCurrency = isFieldNotBlank "Default currency" input.defaultCurrency
            , destinationAccounts = isFieldNotBlank "Destination accounts" input.destinationAccounts
            , sourceAccounts = isFieldNotBlank "Source accounts" input.sourceAccounts
            }

        settings : Result String ValidSettings
        settings =
            Result.map3
                (Settings input.version)
                (results.destinationAccounts |> Result.map (String.split "\n"))
                (results.sourceAccounts |> Result.map (String.split "\n"))
                results.defaultCurrency
                |> Result.map ValidSettings
    in
    settings |> Result.mapError (\_ -> results)


viewFormErrors : List String -> Html Msg
viewFormErrors errors =
    div [ class "ui error message" ]
        (div
            [ class "header" ]
            [ text "Invalid input" ]
            :: (errors |> List.map (\e -> p [] [ text e ]))
        )


settingsDecoder : Json.Decode.Decoder Settings
settingsDecoder =
    Json.Decode.succeed Settings
        |> required "version" Json.Decode.string
        |> required "destinationAccounts" (Json.Decode.list Json.Decode.string)
        |> required "sourceAccounts" (Json.Decode.list Json.Decode.string)
        |> required "defaultCurrency" Json.Decode.string


decodeSettings : Json.Decode.Value -> Result Json.Decode.Error Settings
decodeSettings jsonData =
    Json.Decode.decodeValue settingsDecoder jsonData


port saveSettings : Settings -> Cmd msg


port importSampleData : () -> Cmd msg


port deleteAllData : () -> Cmd msg


port showDeleteAllModal : () -> Cmd msg


port cancelDeleteAll : (Json.Decode.Value -> msg) -> Sub msg


port confirmDeleteAll : (Json.Decode.Value -> msg) -> Sub msg
