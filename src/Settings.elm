port module Settings exposing
    ( Msg(..)
    , Settings
    , State
    , decodeSettings
    , decryptedSettings
    , decryptedSettingsError
    , defaultSettings
    , deleteAllCancelled
    , deleteAllConfirmed
    , emptyState
    , gotEncryptedSettings
    , importSampleData
    , settingsSaved
    , settingsSavedError
    , update
    , viewForm
    )

import Html exposing (Html, div, form, input, label, p, text, textarea)
import Html.Attributes exposing (attribute, class, classList, name, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import Json.Decode.Pipeline exposing (required)
import Misc exposing (cyAttr, dropSuccess, isFieldNotBlank, keepError, viewConfirmModal)


type alias Settings =
    { version : String
    , destinationAccounts : List String
    , sourceAccounts : List String
    , defaultCurrency : String
    }


type ValidSettings
    = ValidSettings Settings (Maybe String)


type alias State =
    { encryption : EncryptionStatus
    , settings : Settings
    , inputs : Inputs
    , results : Maybe Results
    , showCancelButton : Bool
    , saving : Bool
    }


type EncryptionStatus
    = Unknown
    | Encrypted
    | Decrypted String
    | DecryptionError


type alias Inputs =
    { version : String
    , defaultCurrency : String
    , destinationAccounts : String
    , sourceAccounts : String
    , currentPassword : String
    , newPassword : String
    , newPasswordConfirm : String
    }


type alias Results =
    { defaultCurrency : Result String String
    , destinationAccounts : Result String String
    , sourceAccounts : Result String String
    , currentPassword : Result String ()
    , newPassword : Result String (Maybe String)
    }


type Msg
    = EditDefaultCurrency String
    | EditDestinationAccounts String
    | EditSourceAccounts String
    | EditCurrentPassword String
    | EditNewPassword String
    | EditNewPasswordConfirm String
    | Cancel
    | SubmitForm
    | SettingsSaved (Result Json.Decode.Error Settings)
    | SettingsSavedError (Result Json.Decode.Error String)
    | ImportSample
    | DeleteAllRequested
    | DeleteAllCancelled
    | DeleteAllConfirmed
    | GotEncryptedSettings
    | GotDecryptionError
    | GotDecryptionSuccess (Result Json.Decode.Error String)
    | DecryptSettings
    | NoOp


emptyState : State
emptyState =
    { encryption = Unknown
    , settings = defaultSettings
    , inputs =
        { version = ""
        , defaultCurrency = ""
        , destinationAccounts = ""
        , sourceAccounts = ""
        , currentPassword = ""
        , newPassword = ""
        , newPasswordConfirm = ""
        }
    , results = Nothing
    , showCancelButton = False
    , saving = False
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

        EditCurrentPassword password ->
            let
                f =
                    model.inputs

                inputs =
                    { f | currentPassword = password }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditNewPassword password ->
            let
                f =
                    model.inputs

                inputs =
                    { f | newPassword = password }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditNewPasswordConfirm password ->
            let
                f =
                    model.inputs

                inputs =
                    { f | newPasswordConfirm = password }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        Cancel ->
            ( model, Cmd.none, True )

        SubmitForm ->
            let
                isValid =
                    validateForm model.encryption model.inputs

                ( results, cmd ) =
                    case isValid of
                        Err e ->
                            ( Just e, Cmd.none )

                        Ok (ValidSettings settings newPassword) ->
                            ( Nothing, saveSettings ( settings, newPassword ) )
            in
            ( { model | results = results }, cmd, False )

        SettingsSavedError _ ->
            ( { model | saving = False }, Cmd.none, False )

        SettingsSaved (Err _) ->
            ( { model | saving = False }, Cmd.none, False )

        SettingsSaved (Ok settings) ->
            ( { model | settings = settings, saving = False }, Cmd.none, True )

        ImportSample ->
            ( model, importSampleData (), True )

        DeleteAllRequested ->
            ( model, showDeleteAllModal (), False )

        DeleteAllCancelled ->
            ( model, Cmd.none, False )

        DeleteAllConfirmed ->
            ( model, deleteAllData (), True )

        GotEncryptedSettings ->
            ( { model | encryption = Encrypted }, Cmd.none, False )

        GotDecryptionError ->
            ( { model | encryption = DecryptionError }, Cmd.none, False )

        DecryptSettings ->
            ( model, decryptSettings model.inputs.currentPassword, False )

        GotDecryptionSuccess (Ok password) ->
            ( { model | encryption = Decrypted password }, Cmd.none, True )

        GotDecryptionSuccess (Err _) ->
            ( model, Cmd.none, False )

        NoOp ->
            ( model, Cmd.none, False )


viewForm : State -> Html Msg
viewForm model =
    case model.encryption of
        Encrypted ->
            viewFormAskPassword model

        DecryptionError ->
            viewFormAskPassword model

        _ ->
            viewFormDecrypted model


viewFormAskPassword : State -> Html Msg
viewFormAskPassword model =
    let
        errorView =
            if model.encryption == DecryptionError then
                viewFormErrors [ "Invalid password" ]

            else
                div [] []
    in
    div []
        [ form [ class "ui large form", onSubmit DecryptSettings ]
            [ div [ class "field" ]
                [ label [] [ text "Enter password" ]
                , input [ name "currentPassword", type_ "password", cyAttr "current-password", attribute "autocomplete" "current-password", value model.inputs.currentPassword, onInput EditCurrentPassword ] []
                ]
            , div [ class "ui positive button right floated", cyAttr "open", onClick DecryptSettings ]
                [ text "Open" ]
            ]
        , errorView
        ]


viewFormDecrypted : State -> Html Msg
viewFormDecrypted model =
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
                    [ res.defaultCurrency
                    , res.destinationAccounts
                    , res.sourceAccounts
                    , res.currentPassword |> dropSuccess
                    , res.newPassword |> dropSuccess
                    ]
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
             , case model.encryption of
                Decrypted _ ->
                    div [ class "field" ]
                        [ label [] [ text "Current password" ]
                        , input [ name "currentPassword", type_ "password", cyAttr "current-password", attribute "autocomplete" "current-password", value f.currentPassword, onInput EditCurrentPassword ] []
                        ]

                _ ->
                    div [] []
             , div [ class "field" ]
                [ label [] [ text "New password" ]
                , input [ name "newPassword", type_ "password", cyAttr "new-password", attribute "autocomplete" "new-password", value f.newPassword, onInput EditNewPassword ] []
                ]
             , div [ class "field" ]
                [ label [] [ text "Confirm new password" ]
                , input [ name "newPasswordConfirm", type_ "password", cyAttr "new-password-confirm", attribute "autocomplete" "new-password", value f.newPasswordConfirm, onInput EditNewPasswordConfirm ] []
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


validateForm : EncryptionStatus -> Inputs -> Result Results ValidSettings
validateForm encryption input =
    let
        results : Results
        results =
            { defaultCurrency = isFieldNotBlank "Default currency" input.defaultCurrency
            , destinationAccounts = isFieldNotBlank "Destination accounts" input.destinationAccounts
            , sourceAccounts = isFieldNotBlank "Source accounts" input.sourceAccounts
            , currentPassword = validateCurrentPassword encryption input
            , newPassword = validateNewPassword input
            }

        settingsResult : Result String Settings
        settingsResult =
            Result.map3
                (Settings input.version)
                (results.destinationAccounts |> Result.map (String.split "\n"))
                (results.sourceAccounts |> Result.map (String.split "\n"))
                results.defaultCurrency

        settings : Result String ValidSettings
        settings =
            Result.map3
                (\_ -> ValidSettings)
                results.currentPassword
                settingsResult
                results.newPassword
    in
    settings |> Result.mapError (\_ -> results)


validateCurrentPassword : EncryptionStatus -> Inputs -> Result String ()
validateCurrentPassword encryption input =
    case encryption of
        Decrypted password ->
            if password == input.currentPassword then
                Ok ()

            else
                Err "Invalid current password"

        _ ->
            Ok ()


validateNewPassword : Inputs -> Result String (Maybe String)
validateNewPassword input =
    case ( String.isEmpty input.newPassword, String.isEmpty input.newPasswordConfirm ) of
        ( True, True ) ->
            Ok Nothing

        ( _, _ ) ->
            if input.newPassword == input.newPasswordConfirm then
                Ok (Just input.newPassword)

            else
                Err "Passwords don't match"


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


port gotEncryptedSettings : (Json.Decode.Value -> msg) -> Sub msg


port decryptedSettingsError : (Json.Decode.Value -> msg) -> Sub msg


port decryptedSettings : (Json.Decode.Value -> msg) -> Sub msg


port decryptSettings : String -> Cmd msg


port saveSettings : ( Settings, Maybe String ) -> Cmd msg


port importSampleData : () -> Cmd msg


port deleteAllData : () -> Cmd msg


port showDeleteAllModal : () -> Cmd msg


port settingsSaved : (Json.Decode.Value -> msg) -> Sub msg


port settingsSavedError : (Json.Decode.Value -> msg) -> Sub msg


port deleteAllCancelled : (Json.Decode.Value -> msg) -> Sub msg


port deleteAllConfirmed : (Json.Decode.Value -> msg) -> Sub msg
