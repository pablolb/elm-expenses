module TransactionsTests exposing (..)

import Expect
import Helpers exposing (..)
import Json.Decode exposing (decodeString)
import Test exposing (..)
import Time exposing (Month(..))
import Transactions exposing (Transaction, transactionDecoder)


transactionDecoderTest : Test
transactionDecoderTest =
    let
        sample : Transaction
        sample =
            buildTransaction
                (TransactionInput
                    2023
                    Dec
                    29
                    "Supermarket"
                    "Expenses:Groceries"
                    "Assets:Cash"
                    3599
                )

        expected =
            { sample | id = "SomeId", version = "SomeVersion" }
    in
    test "It decodes transactions" <|
        \_ ->
            """
            {
                "id": "SomeId",
                "version": "SomeVersion",
                "date": "2023-12-29",
                "description": "Supermarket",
                "destination": {
                    "account": "Expenses:Groceries",
                    "amount": 3599,
                    "currency": "USD"
                },
                "source": {
                    "account": "Assets:Cash",
                    "amount": -3599,
                    "currency": "USD"
                }
            }
            """
                |> decodeString transactionDecoder
                |> Expect.equal (Ok expected)
