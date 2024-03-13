module EditTransactionTests exposing (..)

import Date
import EditTransaction exposing (Input, Msg(..), Results, emptyState, update, validateForm, viewForm)
import Expect
import Helpers exposing (..)
import Html.Attributes exposing (name, selected, type_, value)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (all, attribute, class, classes, containing, tag, text)
import Time exposing (Month(..))


editDateSetsDateInFormInput : Test
editDateSetsDateInFormInput =
    test "EditDate message sets date in model" <|
        \_ ->
            emptyState
                |> update (EditDate "2024-25-02")
                |> tripleFirst
                |> .input
                |> .date
                |> Expect.equal "2024-25-02"


editDescriptionSetsDescriptionInFormInput : Test
editDescriptionSetsDescriptionInFormInput =
    test "EditDescription message sets description in model" <|
        \_ ->
            emptyState
                |> update (EditDescription "Pizza")
                |> tripleFirst
                |> .input
                |> .description
                |> Expect.equal "Pizza"


editDestinationSetsDestinationInFormInput : Test
editDestinationSetsDestinationInFormInput =
    test "EditDestination message sets destination in model" <|
        \_ ->
            emptyState
                |> update (EditDestination "Expenses:Tests")
                |> tripleFirst
                |> .input
                |> .destination
                |> Expect.equal "Expenses:Tests"


editSourceSetsSourceInFormInput : Test
editSourceSetsSourceInFormInput =
    test "EditSource message sets source in model" <|
        \_ ->
            emptyState
                |> update (EditSource "Assets:Gold")
                |> tripleFirst
                |> .input
                |> .source
                |> Expect.equal "Assets:Gold"


editAmountSetsAmountInFormInput : Test
editAmountSetsAmountInFormInput =
    test "EditAmount message sets amount in model" <|
        \_ ->
            emptyState
                |> update (EditAmount "-10.000,99")
                |> tripleFirst
                |> .input
                |> .amount
                |> Expect.equal "-10.000,99"


submitFormValidatesTheForm : Test
submitFormValidatesTheForm =
    let
        badFormInput : Input
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

        expected : Results
        expected =
            { date = Ok (Date.fromCalendarDate 2024 Mar 3)
            , description = Err "Description cannot be blank"
            , destination = Ok "Expenses:Groceries"
            , source = Ok "Assets:Cash"
            , amount = Err "Invalid amount: "
            , currency = Ok "USD"
            }

        model =
            { emptyState
                | input = badFormInput
            }
    in
    test "When the form is submitted, we validate the current input and set the result in the model" <|
        \_ ->
            model
                |> update SubmitForm
                |> tripleFirst
                |> .results
                |> Expect.equal (Just expected)


editPageRendersValidationErrors : Test
editPageRendersValidationErrors =
    let
        badFormInput : Input
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

        formResult : Results
        formResult =
            { date = Ok (Date.fromCalendarDate 2024 Mar 3)
            , description = Err "Description cannot be blank"
            , destination = Ok "Expenses:Groceries"
            , source = Ok "Assets:Cash"
            , amount = Err "Invalid amount: "
            , currency = Ok "USD"
            }

        model =
            { emptyState
                | input = badFormInput
                , results = Just formResult
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
                |> viewForm
                |> Query.fromHtml
                |> Expect.all expectations


testValidateFormError : Test
testValidateFormError =
    let
        badFormInput : Input
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

        expected : Results
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


tripleFirst : ( a, b, c ) -> a
tripleFirst ( a, _, _ ) =
    a
