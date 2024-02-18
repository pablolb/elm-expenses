module MainTests exposing (..)

import Date
import Expect
import Json.Decode exposing (decodeString)
import Main exposing (..)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (class)
import Time exposing (Month(..))


transactionDecoderTest : Test
transactionDecoderTest =
    let
        expected : Transaction
        expected =
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
    in
    test "It decodes transactions" <|
        \_ ->
            """
            {
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


gotTransactionsSetsListItems : Test
gotTransactionsSetsListItems =
    let
        ( transactions, expected ) =
            buildSampleTransactions ()
    in
    test "It sets ListItems" <|
        \_ ->
            initialModel
                |> update (GotTransactions (Ok transactions))
                |> Tuple.first
                |> .listItems
                |> Expect.equal expected


emptyListItemsIsEmptyList : Test
emptyListItemsIsEmptyList =
    test "No transactions means no rows" <|
        \_ ->
            initialModel
                |> view
                |> Query.fromHtml
                |> Query.findAll [ class "item" ]
                |> Query.count (Expect.equal 0)


transactionsAreGroupedByDate : Test
transactionsAreGroupedByDate =
    let
        ( transactions, listItems ) =
            buildSampleTransactions ()

        model : Model
        model =
            { initialModel | transactions = transactions, listItems = listItems }
    in
    test "Three transactions in two days means five rows" <|
        \_ ->
            model
                |> view
                |> Query.fromHtml
                |> Query.findAll [ class "item" ]
                |> Query.count (Expect.equal 5)


{-| Builds a list of Transactions, and a list of expected ListItems.

We create three transactions:

  - Two for 2023-12-29
  - One for 2023-12-30

We expect 5 ListItems, and we expect them sorted descending by date:

1.  Date 2023-12-30
2.  T3
3.  Date 2023-12-29
4.  T2
5.  T1

-}
buildSampleTransactions : () -> ( List Transaction, List ListItem )
buildSampleTransactions _ =
    let
        t0 : Transaction
        t0 =
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

        t1 : Transaction
        t1 =
            buildTransaction
                (TransactionInput
                    2023
                    Dec
                    29
                    "Gas"
                    "Expenses:Auto"
                    "Assets:Cash"
                    9923
                )

        t2 : Transaction
        t2 =
            buildTransaction
                (TransactionInput
                    2023
                    Dec
                    30
                    "Lunch"
                    "Expenses:Eat Out"
                    "Assets:Cash"
                    9923
                )
    in
    ( [ t0, t1, t2 ], [ D t2.date, T t2, D t1.date, T t1, T t0 ] )


type alias TransactionInput =
    { year : Int
    , month : Month
    , day : Int
    , description : String
    , destination : String
    , source : String
    , amount : Int
    }


buildTransaction : TransactionInput -> Transaction
buildTransaction input =
    Transaction
        (Date.fromCalendarDate input.year input.month input.day)
        input.description
        (Entry input.destination "USD" input.amount)
        (Entry input.source "USD" (-1 * input.amount))
