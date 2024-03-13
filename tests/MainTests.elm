module MainTests exposing (..)

import EditTransaction
import Expect
import Helpers exposing (..)
import Main exposing (..)
import Settings
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (class)
import Time exposing (Month(..))


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


setPageSetsPage : Test
setPageSetsPage =
    test "SetPage message sets current page in model" <|
        \_ ->
            initialModel
                |> update (SetPage Edit)
                |> Tuple.first
                |> .currentPage
                |> Expect.equal Edit


editViewResetsForm : Test
editViewResetsForm =
    let
        editTransactionState : EditTransaction.State
        editTransactionState =
            { input =
                { id = ""
                , version = ""
                , date = "2024-03-03"
                , description = "Pizza"
                , destination = "Expenses:Eat Out & Take Away"
                , source = "Liabilities:CreditCard"
                , amount = "19.90"
                , currency = "USD"
                , extraDestinations = []
                , extraSources = []
                }
            , results = Nothing
            , settings = Settings.defaultSettings
            }

        model : Model
        model =
            { initialModel | editTransactionState = editTransactionState }

        formInputExpectaion : Model -> Expect.Expectation
        formInputExpectaion m =
            Expect.equal (defaultFormInput initialModel) m.editTransactionState.input

        expectations : List (Model -> Expect.Expectation)
        expectations =
            [ formInputExpectaion
            ]
    in
    test "SetPage Edit rests form" <|
        \_ ->
            model
                |> update (SetPage Edit)
                |> Tuple.first
                |> Expect.all expectations
