Feature: Users should be able to edit settings

    Background: A user who already has transactions goes to settings
        Given I have saved the default settings
        And I have saved the following transactions:
            | date       | description  | destination       | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas | Assets:PayPal | 1999   | USD      |
        When I go to settings

    Scenario: I see more buttons
        Then I see the "Cancel" button
        And I see the "Import Sample" button
        And I see the "Delete All Data" button

    Scenario: I see my current settings
        Then the default currency is "USD"
        And the expense accounts are:
            | Expenses:Groceries           |
            | Expenses:Eat Out & Take Away |
        And the source accounts are:
            | Assets:Cash            |
            | Assets:Bank:Checking   |
            | Liabilities:CreditCard |


    Scenario: I change my settings
        When I set the default currency to "ARS"
        And I set the expense accounts to:
            | Expenses:Health & Beauty |
        And I set the source accounts to:
            | Assets:Bitcoin |
        And I save my settings
        When I go to add a transaction
        Then the selected expense account is "Expenses:Health & Beauty"
        And the selected source account is "Assets:Bitcoin"
        When I enter the date "2024-02-28"
        And I enter the description "Spa"
        And I enter the amount "199000"
        And I save the transaction
        Then I see "ARS 199,000.00"

    Scenario: I can import sample data
        When I click the "Import Sample" button
        Then I see "Holiday travel expenses"

    Scenario: I can delete all data
        When I click the "Delete All Data" button
        And I answer "yes" in the confirmation message
        Then I see "Welcome to Elm Expenses!"

    Scenario: I can cancel when deleting all data
        When I click the "Delete All Data" button
        And I answer "no" in the confirmation message
        Then I see the "Delete All Data" button

    Scenario: I cannot store empty settings
        When I set the default currency to an empty string
        And I set the expense accounts to an empty string
        And I set the source accounts to an empty string
        And I save my settings
        Then I see an error message "Default currency cannot be blank"
        And I see an error message "Destination accounts cannot be blank"
        And I see an error message "Source accounts cannot be blank"


