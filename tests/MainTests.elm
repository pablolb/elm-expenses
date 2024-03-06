module MainTests exposing (..)

import Date
import Expect
import Html.Attributes exposing (name, selected, type_, value)
import Json.Decode exposing (decodeString)
import Main exposing (..)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (all, attribute, class, classes, containing, tag, text)
import Time exposing (Month(..))


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
        formInput : FormInput
        formInput =
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

        transaction : Transaction
        transaction =
            buildTransaction
                (TransactionInput
                    2024
                    Mar
                    3
                    "Pizza"
                    "Expenses:Eat Out & Take Away"
                    "Liabilities:CreditCard"
                    1990
                )

        model : Model
        model =
            { initialModel | formInput = formInput, formValidation = Valid transaction }

        formInputExpectaion : Model -> Expect.Expectation
        formInputExpectaion m =
            Expect.equal (defaultFormInput initialModel) m.formInput

        formValidationExpectation : Model -> Expect.Expectation
        formValidationExpectation m =
            Expect.equal None m.formValidation

        expectations : List (Model -> Expect.Expectation)
        expectations =
            [ formInputExpectaion
            , formValidationExpectation
            ]
    in
    test "SetPage Edit rests form" <|
        \_ ->
            model
                |> update (SetPage Edit)
                |> Tuple.first
                |> Expect.all expectations


editDateSetsDateInFormInput : Test
editDateSetsDateInFormInput =
    test "EditDate message sets date in model" <|
        \_ ->
            initialModel
                |> update (EditDate "2024-25-02")
                |> Tuple.first
                |> .formInput
                |> .date
                |> Expect.equal "2024-25-02"


editDescriptionSetsDescriptionInFormInput : Test
editDescriptionSetsDescriptionInFormInput =
    test "EditDescription message sets description in model" <|
        \_ ->
            initialModel
                |> update (EditDescription "Pizza")
                |> Tuple.first
                |> .formInput
                |> .description
                |> Expect.equal "Pizza"


editDestinationSetsDestinationInFormInput : Test
editDestinationSetsDestinationInFormInput =
    test "EditDestination message sets destination in model" <|
        \_ ->
            initialModel
                |> update (EditDestination "Expenses:Tests")
                |> Tuple.first
                |> .formInput
                |> .destination
                |> Expect.equal "Expenses:Tests"


editSourceSetsSourceInFormInput : Test
editSourceSetsSourceInFormInput =
    test "EditSource message sets source in model" <|
        \_ ->
            initialModel
                |> update (EditSource "Assets:Gold")
                |> Tuple.first
                |> .formInput
                |> .source
                |> Expect.equal "Assets:Gold"


editAmountSetsAmountInFormInput : Test
editAmountSetsAmountInFormInput =
    test "EditAmount message sets amount in model" <|
        \_ ->
            initialModel
                |> update (EditAmount "-10.000,99")
                |> Tuple.first
                |> .formInput
                |> .amount
                |> Expect.equal "-10.000,99"


submitFormValidatesTheForm : Test
submitFormValidatesTheForm =
    let
        badFormInput : FormInput
        badFormInput =
            { id = ""
            , version = ""
            , date = "2024-03-03"
            , description = ""
            , destination = "Expenses:Groceries"
            , source = "Assets:Cash"
            , amount = ""
            , currency = "USD"
            , extraDestinations = []
            , extraSources = []
            }

        expected : FormResult
        expected =
            { date = Ok (Date.fromCalendarDate 2024 Mar 3)
            , description = Err "Description cannot be blank"
            , destination = Ok "Expenses:Groceries"
            , source = Ok "Assets:Cash"
            , amount = Err "Invalid amount: "
            , currency = Ok "USD"
            }

        model =
            { initialModel
                | formInput = badFormInput
                , currentPage = Edit
            }
    in
    test "When the form is submitted, we validate the current input and set the result in the model" <|
        \_ ->
            model
                |> update SubmitForm
                |> Tuple.first
                |> .formValidation
                |> Expect.equal (Error expected)


editPageRendersFormInput : Test
editPageRendersFormInput =
    let
        formInput : FormInput
        formInput =
            { id = ""
            , version = ""
            , date = "2024-03-03"
            , description = "Pizza"
            , destination = "Expenses:Eat Out & Take Away"
            , source = "Liabilities:CreditCard"
            , amount = "19.90"
            , currency = "EUR"
            , extraDestinations = []
            , extraSources = []
            }

        model : Model
        model =
            { initialModel | formInput = formInput, currentPage = Edit }

        expectations : List (Query.Single Msg -> Expect.Expectation)
        expectations =
            [ \q ->
                q
                    |> Query.findAll [ tag "input", attribute (type_ "date"), attribute (value "2024-03-03") ]
                    |> Query.count (Expect.equal 1)
            , \q ->
                q
                    |> Query.findAll [ tag "input", attribute (name "description"), attribute (value "Pizza") ]
                    |> Query.count (Expect.equal 1)
            , \q ->
                q
                    |> Query.find [ tag "select", attribute (name "destination") ]
                    |> Query.children [ tag "option", attribute (value "Expenses:Eat Out & Take Away"), attribute (selected True) ]
                    |> Query.count (Expect.equal 1)
            , \q ->
                q
                    |> Query.find [ tag "select", attribute (name "source") ]
                    |> Query.children [ tag "option", attribute (value "Liabilities:CreditCard"), attribute (selected True) ]
                    |> Query.count (Expect.equal 1)
            , \q ->
                q
                    |> Query.findAll [ tag "input", attribute (name "amount"), attribute (value "19.90") ]
                    |> Query.count (Expect.equal 1)
            ]
    in
    test "Edit Form renders from input" <|
        \_ ->
            model
                |> view
                |> Query.fromHtml
                |> Expect.all expectations


editPageRendersValidationErrors : Test
editPageRendersValidationErrors =
    let
        badFormInput : FormInput
        badFormInput =
            { id = ""
            , version = ""
            , date = "2024-03-03"
            , description = ""
            , destination = "Expenses:Groceries"
            , source = "Assets:Cash"
            , amount = ""
            , currency = "USD"
            , extraDestinations = []
            , extraSources = []
            }

        formResult : FormResult
        formResult =
            { date = Ok (Date.fromCalendarDate 2024 Mar 3)
            , description = Err "Description cannot be blank"
            , destination = Ok "Expenses:Groceries"
            , source = Ok "Assets:Cash"
            , amount = Err "Invalid amount: "
            , currency = Ok "USD"
            }

        model =
            { initialModel
                | formInput = badFormInput
                , formValidation = Error formResult
                , currentPage = Edit
            }

        expectations : List (Query.Single Msg -> Expect.Expectation)
        expectations =
            [ \q ->
                q
                    |> Query.has
                        [ all
                            [ tag "div"
                            , classes [ "field", "error" ]
                            , containing [ tag "input", attribute (name "description") ]
                            ]
                        ]
            , \q ->
                q
                    |> Query.has
                        [ all
                            [ tag "div"
                            , classes [ "field", "error" ]
                            , containing [ tag "input", attribute (name "amount") ]
                            ]
                        ]
            , \q ->
                q
                    |> Query.has
                        [ all
                            [ tag "div"
                            , classes [ "ui", "error", "message" ]
                            , all
                                [ containing [ tag "p", text "Description cannot be blank" ]
                                , containing [ tag "p", text "Invalid amount:" ]
                                ]
                            ]
                        ]
            ]
    in
    test "Edit Form renders validation errors" <|
        \_ ->
            model
                |> view
                |> Query.fromHtml
                |> Expect.all expectations


testValidateFormError : Test
testValidateFormError =
    let
        badFormInput : FormInput
        badFormInput =
            { id = ""
            , version = ""
            , date = ""
            , description = ""
            , destination = ""
            , source = ""
            , amount = ""
            , currency = ""
            , extraDestinations = []
            , extraSources = []
            }

        expected : FormResult
        expected =
            { date = Err "Expected a date in ISO 8601 format"
            , description = Err "Description cannot be blank"
            , destination = Err "Destination cannot be blank"
            , source = Err "Source cannot be blank"
            , amount = Err "Invalid amount: "
            , currency = Err "Currency cannot be blank"
            }
    in
    test "validateForm where all are errors" <|
        \_ ->
            badFormInput
                |> validateForm
                |> Expect.equal (Err expected)


testValidateFormSuccess : Test
testValidateFormSuccess =
    let
        badFormInput : FormInput
        badFormInput =
            { id = ""
            , version = ""
            , date = "2024-03-01"
            , description = "Supermarket"
            , destination = "Expenses:Groceries"
            , source = "Assets:Cash"
            , amount = "19.9"
            , currency = "USD"
            , extraDestinations = []
            , extraSources = []
            }

        expected : Transaction
        expected =
            buildTransaction
                (TransactionInput
                    2024
                    Mar
                    1
                    "Supermarket"
                    "Expenses:Groceries"
                    "Assets:Cash"
                    1990
                )
    in
    test "validateForm where there are no are errors" <|
        \_ ->
            badFormInput
                |> validateForm
                |> Expect.equal (Ok expected)


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
