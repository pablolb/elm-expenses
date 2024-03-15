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
        And I answer "yes" in the confirmation message
        Then I should not see "Pizza"

    Scenario: Deleting a transaction can be cancelled
        Given I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        When I click on "Pizza"
        And I click the "Delete" button
        And I answer "no" in the confirmation message
        Then the description is "Pizza"

    Scenario: I can switch to advanced edit mode
        When I go to add a transaction
        Then the advanced mode toggle is off
        When I toggle the advanced mode
        Then I don't see the expense account dropdown
        And I don't see the source account dropdown
        And I see a destination account text input
        And I see a source account text input
        And I see a currency text input
        And the advanced mode toggle is on


    Scenario: I can add transactions with new accounts and new currency
        When I go to add a transaction
        And I toggle the advanced mode
        And I enter the date "2024-02-28"
        And I enter the description "Car repair"
        And I enter the amount "690.90"
        And I enter the currency "EUR"
        And I enter the destination account "Expenses:Auto:Repair"
        And I enter the source account "Liabilities:Loans"
        And I save the transaction
        Then I see "Car repair"
        And I see "L:Loans ↦ E:A:Repair"
        And I see "EUR 690.90"

    Scenario: It auto-completes destination and source accounts in Sipmle Mode
        Given I have saved the following transactions:
            | date       | description  | destination       | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas | Assets:PayPal | 1999   | USD      |
        When I go to add a transaction
        And I enter the description "Fill-up tank"
        Then the selected expense account is "Expenses:Auto:Gas"
        Then the selected source account is "Assets:PayPal"

    Scenario: It auto-completes destination and source accounts in Advanced Mode
        Given I have saved the following transactions:
            | date       | description  | destination       | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas | Assets:PayPal | 1999   | USD      |
        When I go to add a transaction
        And I toggle the advanced mode
        And I enter the description "Fill-up tank"
        Then the destination account is "Expenses:Auto:Gas"
        Then the source account is "Assets:PayPal"


