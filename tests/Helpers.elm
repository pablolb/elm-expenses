module Helpers exposing (..)

import Date
import Main exposing (ListItem(..))
import Time exposing (Month(..))
import Transactions exposing (Entry, Transaction)


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
        ""
        ""
        (Date.fromCalendarDate input.year input.month input.day)
        input.description
        (Entry input.destination "USD" input.amount)
        (Entry input.source "USD" (-1 * input.amount))
