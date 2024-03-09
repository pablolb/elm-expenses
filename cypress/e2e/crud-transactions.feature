Feature: Users should be able to create, update, and delete transactions

    Background: A user who has chosen his default settings
        Given I have saved the default settings

    Scenario: I can add a transaction
        When I go to add a transaction
        And I enter the date "2024-02-29"
        And I enter the description "Pizza"
        And I enter the amount "19.90"
        And I select the expense account "Expenses:Eat Out & Take Away"
        And I select the source account "Assets:Bank:Checking"
        And I save the transaction
        Then I see "29 Feb"
        And I see "Pizza"
        And I see "A:B:Checking ↦ E:Eat Out & Take Away"
        And I see "USD 19.90"

    Scenario: Clicking on a transaction opens up the editor
        Given I have saved the following transactions:
            | date       | description  | destination       | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas | Assets:PayPal | 1999   | USD      |
        When I click on "Fill-up tank"
        Then the date is "2024-02-29"
        And the description is "Fill-up tank"
        And the selected expense account is "Expenses:Auto:Gas"
        And the selected source account is "Assets:PayPal"
        And the amount is "19.99"

    Scenario: Editing a transaction persists the new changes
        Given I have saved the following transactions:
            | date       | description  | destination       | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas | Assets:PayPal | 1999   | USD      |
        When I click on "Fill-up tank"
        And I enter the date "2024-02-28"
        And I enter the description "Pizza"
        And I enter the amount "19.90"
        And I select the expense account "Expenses:Eat Out & Take Away"
        And I select the source account "Assets:Bank:Checking"
        And I save the transaction
        Then I see "28 Feb"
        And I see "Pizza"
        And I see "A:B:Checking ↦ E:Eat Out & Take Away"
        And I see "USD 19.90"

    Scenario: Deleting a transaction
        Given I have saved the following transactions:
            | date       | description  | destination                  | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas            | Assets:PayPal | 1999   | USD      |
            | 2024-03-01 | Pizza        | Expenses:Eat Out & Take Away | Assets:Cash   | 3999   | USD      |
        When I click on "Pizza"
        And I click the "Delete" button
        Then I should not see "Pizza"
