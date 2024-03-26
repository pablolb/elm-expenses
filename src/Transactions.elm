module Transactions exposing (..)

import Date exposing (Date)
import Json.Decode
import Json.Decode.Pipeline exposing (required)


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


transactionToJson : Transaction -> JsonTransaction
transactionToJson txn =
    JsonTransaction txn.id txn.version (Date.toIsoString txn.date) txn.description txn.destination txn.source


type BalanceError
    = AllZeroError
    | MultiCurrencyError
    | NotBalanced Int


isBalanced : Transaction -> Result BalanceError Transaction
isBalanced txn =
    let
        diff =
            txn.destination.amount + txn.source.amount
    in
    if txn.source.amount == 0 && txn.destination.amount == 0 then
        Err AllZeroError

    else if txn.source.currency /= txn.destination.currency then
        Err MultiCurrencyError

    else if diff == 0 then
        Ok txn

    else
        Err (NotBalanced diff)



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


transactionsDecoder : Json.Decode.Decoder (List Transaction)
transactionsDecoder =
    Json.Decode.list transactionDecoder


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
