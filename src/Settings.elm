port module Settings exposing
    ( EncryptionStatus(..)
    , Msg(..)
    , ReplicationSettings
    , Settings
    , State
    , Working(..)
    , decodeSettings
    , decryptedSettings
    , decryptedSettingsError
    , defaultSettings
    , deleteAllCancelled
    , deleteAllConfirmed
    , emptyState
    , gotE2EJsonLoaded
    , gotEncryptedSettings
    , importSampleData
    , requestImportJson
    , settingsSaved
    , settingsSavedError
    , transactionsImported
    , transactionsImportedError
    , update
    , viewForm
    )

import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, div, form, h4, i, input, label, p, span, text, textarea)
import Html.Attributes exposing (attribute, checked, class, classList, for, id, name, placeholder, tabindex, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import Json.Decode.Pipeline exposing (optional, required)
import Maybe exposing (withDefault)
import Misc exposing (cyAttr, dropSuccess, isError, isFieldNotBlank, keepError, viewConfirmModal)
import Task
import Transactions exposing (JsonTransaction, isBalanced, transactionToJson, transactionsDecoder)


type alias Settings =
    { version : String
    , destinationAccounts : List String
    , sourceAccounts : List String
    , defaultCurrency : String
    , replication : Maybe ReplicationSettings
    }


type ValidSettings
    = ValidSettings Settings (Maybe String)


type alias State =
    { encryption : EncryptionStatus
    , settings : Settings
    , inputs : Inputs
    , results : Maybe Results
    , showCancelButton : Bool
    , error : Maybe String
    , working : Working
    }


type Working
    = NotWorking
    | Saving
    | Importing


type EncryptionStatus
    = Unknown
    | Encrypted
    | Decrypted String
    | DecryptionError


type alias ReplicationSettings =
    { url : String
    , username : String
    , password : String
    }


type alias Inputs =
    { version : String
    , defaultCurrency : String
    , destinationAccounts : String
    , sourceAccounts : String
    , encryption : Bool
    , currentPassword : String
    , newPassword : String
    , newPasswordConfirm : String
    , replication : Bool
    , replicationUrl : String
    , replicationUsername : String
    , replicationPassword : String
    }


type alias Results =
    { defaultCurrency : Result String String
    , destinationAccounts : Result String String
    , sourceAccounts : Result String String
    , newPassword : Result String (Maybe String)
    , replication : Result String (Maybe ReplicationSettings)
    }


type Msg
    = EditDefaultCurrency String
    | EditDestinationAccounts String
    | EditSourceAccounts String
    | ToggleEncryption
    | EditCurrentPassword String
    | EditNewPassword String
    | EditNewPasswordConfirm String
    | ToggleReplication
    | EditReplicationUrl String
    | EditReplicationUsername String
    | EditReplicationPassword String
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
    | JsonRequested
    | JsonSelected File
    | JsonLoaded String
    | GotE2EJsonLoaded (Result Json.Decode.Error String)
    | TransactionsImported
    | TransactionsImportedError (Result Json.Decode.Error String)
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
        , encryption = True
        , currentPassword = ""
        , newPassword = ""
        , newPasswordConfirm = ""
        , replication = False
        , replicationUrl = ""
        , replicationUsername = ""
        , replicationPassword = ""
        }
    , error = Nothing
    , results = Nothing
    , showCancelButton = False
    , working = NotWorking
    }


defaultSettings : Settings
defaultSettings =
    { version = ""
    , destinationAccounts = [ "Expenses:Groceries", "Expenses:Eat Out & Take Away" ]
    , sourceAccounts = [ "Assets:Cash", "Assets:Bank:Checking", "Liabilities:CreditCard" ]
    , defaultCurrency = "USD"
    , replication = Nothing
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

        ToggleEncryption ->
            let
                f =
                    model.inputs

                inputs =
                    { f | encryption = not f.encryption }
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

        ToggleReplication ->
            let
                f =
                    model.inputs

                inputs =
                    { f | replication = not f.replication }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditReplicationUsername username ->
            let
                f =
                    model.inputs

                inputs =
                    { f | replicationUsername = username }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditReplicationUrl url ->
            let
                f =
                    model.inputs

                inputs =
                    { f | replicationUrl = url }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        EditReplicationPassword password ->
            let
                f =
                    model.inputs

                inputs =
                    { f | replicationPassword = password }
            in
            ( { model | inputs = inputs }, Cmd.none, False )

        Cancel ->
            ( model, Cmd.none, True )

        SubmitForm ->
            let
                isValid =
                    validateForm (isFirstRun model.settings) model.inputs

                ( results, cmd, working ) =
                    case isValid of
                        Err e ->
                            ( Just e, Cmd.none, model.working )

                        Ok (ValidSettings settings newPassword) ->
                            ( Nothing, saveSettings ( settings, newPassword ), Saving )
            in
            ( { model | results = results, working = working }, cmd, False )

        SettingsSavedError _ ->
            ( { model | working = NotWorking }, Cmd.none, False )

        SettingsSaved (Err _) ->
            ( { model | working = NotWorking }, Cmd.none, False )

        SettingsSaved (Ok settings) ->
            ( { model | settings = settings, working = NotWorking }, Cmd.none, True )

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

        JsonRequested ->
            ( model, requestImportJson JsonSelected, False )

        JsonSelected file ->
            ( { model | working = Importing }, Task.perform JsonLoaded (File.toString file), False )

        JsonLoaded jsonString ->
            let
                ( cmd, error, working ) =
                    case Json.Decode.decodeString transactionsDecoder jsonString of
                        Ok txns ->
                            let
                                errors =
                                    txns |> List.map isBalanced |> List.filter isError
                            in
                            if List.isEmpty errors then
                                ( List.map transactionToJson txns |> importTransactions, Nothing, model.working )

                            else
                                ( Cmd.none, Just "Some transactions are not balanced or not supported!", NotWorking )

                        Err e ->
                            ( Cmd.none, Just ("Error decoding JSON: " ++ Json.Decode.errorToString e), NotWorking )
            in
            ( { model | error = error, working = working }, cmd, False )

        TransactionsImported ->
            ( { model | working = NotWorking }, Cmd.none, True )

        TransactionsImportedError _ ->
            ( { model | working = NotWorking }, Cmd.none, False )

        GotE2EJsonLoaded (Err _) ->
            ( { model | working = NotWorking }, Cmd.none, False )

        GotE2EJsonLoaded (Ok string) ->
            let
                newModel =
                    { model | working = Importing }
            in
            update (JsonLoaded string) newModel

        NoOp ->
            ( model, Cmd.none, False )


viewForm : State -> ( Html Msg, List (Html Msg) )
viewForm model =
    case model.encryption of
        Encrypted ->
            viewFormAskPassword model

        DecryptionError ->
            viewFormAskPassword model

        _ ->
            viewFormDecrypted model


viewFormAskPassword : State -> ( Html Msg, List (Html Msg) )
viewFormAskPassword model =
    let
        errorView =
            if model.encryption == DecryptionError then
                viewFormErrors [ "Invalid password" ]

            else
                div [] []
    in
    ( div []
        [ form [ class "ui large form", onSubmit DecryptSettings ]
            [ div [ class "field" ]
                [ label [] [ text "Enter password" ]
                , input [ name "currentPassword", type_ "password", cyAttr "current-password", attribute "autocomplete" "current-password", value model.inputs.currentPassword, onInput EditCurrentPassword ] []
                ]
            ]
        , errorView
        ]
    , [ div [ class "right menu" ]
            [ div [ class "ui positive button right floated", cyAttr "open", onClick DecryptSettings ]
                [ text "Open" ]
            ]
      ]
    )


viewFormDecrypted : State -> ( Html Msg, List (Html Msg) )
viewFormDecrypted model =
    let
        f =
            model.inputs

        workingIcon : Html Msg
        workingIcon =
            if model.working == Importing then
                div [ class "item" ]
                    [ i [ class "loading spinner icon" ] []
                    ]

            else
                span [] []

        otherButtons =
            if model.showCancelButton then
                [ div [ class "item" ] [ div [ class "ui button", cyAttr "cancel", onClick Cancel ] [ text "Cancel" ] ]
                , div [ class "ui dropdown item needs-js-menu" ]
                    [ text "More"
                    , i [ class "caret up icon" ] []
                    , div [ class "menu" ]
                        [ div [ class "item", cyAttr "import-sample", onClick ImportSample ]
                            [ i [ class "angle double down icon" ] []
                            , text "Import sample"
                            ]
                        , div [ class "item", cyAttr "import-sample", classList [ ( "disabled", model.working /= NotWorking ) ], cyAttr "import-json", onClick JsonRequested ]
                            [ i [ class "folder open icon" ] []
                            , text "Import JSON"
                            ]
                        , div [ class "item", cyAttr "delete-all-data", onClick DeleteAllRequested ]
                            [ i [ class "delete icon" ] []
                            , text "Deleta ALL data"
                            ]
                        ]
                    ]
                , workingIcon
                ]

            else
                []

        error : List String
        error =
            case model.error of
                Just e ->
                    [ e ]

                _ ->
                    []

        errors : List String
        errors =
            case model.results of
                Nothing ->
                    [] ++ error

                Just res ->
                    [ res.defaultCurrency
                    , res.destinationAccounts
                    , res.sourceAccounts
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
    ( div []
        [ form [ class "ui large form", classList [ ( "error", hadErrors ) ], onSubmit SubmitForm ]
            ([ div [ class "field", classList [ ( "error", isFieldError model.results .defaultCurrency ) ] ]
                [ label [] [ text "Default currency" ]
                , input [ name "defaultCurrency", cyAttr "default-currency", placeholder "USD", value f.defaultCurrency, onInput EditDefaultCurrency ] []
                ]
             , div [ class "field", classList [ ( "error", isFieldError model.results .destinationAccounts ) ] ]
                [ label [] [ text "Expense accounts" ]
                , textarea [ name "destinationAccounts", cyAttr "destination-accounts", placeholder "Expenses:Groceries\nExpenses:Eat Out & Take Away", value f.destinationAccounts, onInput EditDestinationAccounts ] []
                ]
             , div [ class "field", classList [ ( "error", isFieldError model.results .sourceAccounts ) ] ]
                [ label [] [ text "Source accounts" ]
                , textarea [ name "sourceAccounts", cyAttr "source-accounts", placeholder "Assets:Cash\nLiabilities:CreditCard", value f.sourceAccounts, onInput EditSourceAccounts ] []
                ]
             ]
                ++ viewMaybeEncryptionPart model
                ++ viewReplicationPart model
                ++ [ errorView ]
            )
        , viewConfirmModal
        ]
    , otherButtons
        ++ [ div [ class "right menu" ]
                [ div [ class "item", classList [ ( "disabled", model.working /= NotWorking ) ], cyAttr "save", onClick SubmitForm ]
                    [ button [ class "ui positive button right floated" ]
                        [ text "Save" ]
                    ]
                ]
           ]
    )


viewMaybeEncryptionPart : State -> List (Html Msg)
viewMaybeEncryptionPart model =
    if isFirstRun model.settings then
        viewEncryptionPart model

    else
        []


viewEncryptionPart : State -> List (Html Msg)
viewEncryptionPart model =
    let
        f =
            model.inputs

        content : List (Html Msg)
        content =
            if f.encryption then
                viewEncryptionPartOn model

            else
                []
    in
    [ h4 [ class "ui dividing header" ] [ text "Encryption" ]
    , div [ class "ui segment" ]
        (div [ class "field" ]
            [ div [ class "ui toggle checkbox" ]
                [ input [ id "toggle-encryption", type_ "checkbox", cyAttr "toggle-encryption", checked f.encryption, onClick ToggleEncryption ] []
                , label [ for "toggle-encryption" ] [ text "Encrypt local database" ]
                ]
            ]
            :: content
        )
    ]


viewEncryptionPartOn : State -> List (Html Msg)
viewEncryptionPartOn model =
    let
        f =
            model.inputs
    in
    [ div [ class "ui info message" ]
        [ div [ class "header" ] [ text "This cannot be changed later!" ]
        , p [] [ text "Use a password manager or write down this password in a safe place." ]
        , p [] [ text "Data cannot be recovered without it." ]
        ]
    , div
        [ class "field"
        , classList
            [ ( "disabled", not f.encryption )
            , ( "error", isFieldError model.results .newPassword )
            ]
        ]
        [ label [] [ text "Encryption password" ]
        , input [ name "newPassword", type_ "password", cyAttr "new-password", attribute "autocomplete" "new-password", value f.newPassword, onInput EditNewPassword ] []
        ]
    , div
        [ class "field"
        , classList
            [ ( "disabled", not f.encryption )
            , ( "error", isFieldError model.results .newPassword )
            ]
        ]
        [ label [] [ text "Confirm encryption password" ]
        , input [ name "newPasswordConfirm", type_ "password", cyAttr "new-password-confirm", attribute "autocomplete" "new-password", value f.newPasswordConfirm, onInput EditNewPasswordConfirm ] []
        ]
    ]


viewReplicationPart : State -> List (Html Msg)
viewReplicationPart model =
    let
        f =
            model.inputs

        content : List (Html Msg)
        content =
            if f.replication then
                viewReplicationPartOn model

            else
                []
    in
    [ h4 [ class "ui dividing header" ] [ text "Replication" ]
    , div [ class "ui segment" ]
        (div [ class "field" ]
            [ div [ class "ui toggle checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , id "toggle-replication"
                    , cyAttr "toggle-replication"
                    , tabindex 0
                    , checked f.replication
                    , onClick ToggleReplication
                    ]
                    []
                , label [ for "toggle-replication" ] [ text "Replicate local databse" ]
                ]
            ]
            :: content
        )
    ]


viewReplicationPartOn : State -> List (Html Msg)
viewReplicationPartOn model =
    let
        f =
            model.inputs

        isError =
            isFieldError model.results .replication
    in
    [ div [ class "field", classList [ ( "error", isError ) ] ]
        [ label [] [ text "Replication URL" ]
        , input
            [ name "replicationUrl"
            , cyAttr "replication-url"
            , placeholder "https://couchdb.org:6984/user-adf"
            , value f.replicationUrl
            , onInput EditReplicationUrl
            ]
            []
        ]
    , div [ class "field", classList [ ( "error", isError ) ] ]
        [ label [] [ text "Replication username" ]
        , input
            [ name "replicationUsername"
            , cyAttr "replication-username"
            , placeholder "john"
            , value f.replicationUsername
            , onInput EditReplicationUsername
            ]
            []
        ]
    , div [ class "field", classList [ ( "error", isError ) ] ]
        [ label [] [ text "Replication password" ]
        , input
            [ name "replicationPassword"
            , type_ "password"
            , cyAttr "replication-password"
            , attribute "autocomplete" "none"
            , value f.replicationPassword
            , onInput EditReplicationPassword
            ]
            []
        ]
    ]


isFieldError : Maybe Results -> (Results -> Result a b) -> Bool
isFieldError results accessor =
    results
        |> Maybe.map accessor
        |> Maybe.map isError
        |> withDefault False


validateForm : Bool -> Inputs -> Result Results ValidSettings
validateForm doValidateNewPassword input =
    let
        newPasswordResult : Result String (Maybe String)
        newPasswordResult =
            if doValidateNewPassword then
                validateNewPassword input

            else
                Ok Nothing

        results : Results
        results =
            { defaultCurrency = isFieldNotBlank "Default currency" input.defaultCurrency
            , destinationAccounts = isFieldNotBlank "Destination accounts" input.destinationAccounts
            , sourceAccounts = isFieldNotBlank "Source accounts" input.sourceAccounts
            , newPassword = newPasswordResult
            , replication = validateReplication input
            }

        settingsResult : Result String Settings
        settingsResult =
            Result.map4
                (Settings input.version)
                (results.destinationAccounts |> Result.map (String.split "\n"))
                (results.sourceAccounts |> Result.map (String.split "\n"))
                results.defaultCurrency
                results.replication

        settings : Result String ValidSettings
        settings =
            Result.map2
                ValidSettings
                settingsResult
                results.newPassword
    in
    settings |> Result.mapError (\_ -> results)


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


validateReplication : Inputs -> Result String (Maybe ReplicationSettings)
validateReplication input =
    if input.replication then
        Result.map3 ReplicationSettings
            (isFieldNotBlank "Replication URL" input.replicationUrl)
            (isFieldNotBlank "Replication username" input.replicationUsername)
            (isFieldNotBlank "Replication password" input.replicationPassword)
            |> Result.map Just

    else
        Ok Nothing


viewFormErrors : List String -> Html Msg
viewFormErrors errors =
    div [ class "ui error message" ]
        (div
            [ class "header" ]
            [ text "Invalid input" ]
            :: (errors |> List.map (\e -> p [] [ text e ]))
        )


requestImportJson : (File -> msg) -> Cmd msg
requestImportJson a =
    Select.file [ "application/json" ] a


isFirstRun : Settings -> Bool
isFirstRun settings =
    settings.version == ""


replicationSettingsDecoder : Json.Decode.Decoder ReplicationSettings
replicationSettingsDecoder =
    Json.Decode.succeed ReplicationSettings
        |> required "url" Json.Decode.string
        |> required "username" Json.Decode.string
        |> required "password" Json.Decode.string


settingsDecoder : Json.Decode.Decoder Settings
settingsDecoder =
    Json.Decode.succeed Settings
        |> required "version" Json.Decode.string
        |> required "destinationAccounts" (Json.Decode.list Json.Decode.string)
        |> required "sourceAccounts" (Json.Decode.list Json.Decode.string)
        |> required "defaultCurrency" Json.Decode.string
        |> optional "replication" (Json.Decode.nullable replicationSettingsDecoder) Nothing


decodeSettings : Json.Decode.Value -> Result Json.Decode.Error Settings
decodeSettings jsonData =
    Json.Decode.decodeValue settingsDecoder jsonData


port gotEncryptedSettings : (Json.Decode.Value -> msg) -> Sub msg


port decryptedSettingsError : (Json.Decode.Value -> msg) -> Sub msg


port decryptedSettings : (Json.Decode.Value -> msg) -> Sub msg


port importTransactions : List JsonTransaction -> Cmd msg


port decryptSettings : String -> Cmd msg


port saveSettings : ( Settings, Maybe String ) -> Cmd msg


port importSampleData : () -> Cmd msg


port deleteAllData : () -> Cmd msg


port showDeleteAllModal : () -> Cmd msg


port settingsSaved : (Json.Decode.Value -> msg) -> Sub msg


port settingsSavedError : (Json.Decode.Value -> msg) -> Sub msg


port deleteAllCancelled : (Json.Decode.Value -> msg) -> Sub msg


port deleteAllConfirmed : (Json.Decode.Value -> msg) -> Sub msg


port gotE2EJsonLoaded : (Json.Decode.Value -> msg) -> Sub msg


port transactionsImported : (Json.Decode.Value -> msg) -> Sub msg


port transactionsImportedError : (Json.Decode.Value -> msg) -> Sub msg
