Feature: Users must choose their default settings to use the app

    Scenario: A user opens the app for the first time
        Then I see "Welcome to Elm Expenses!"
        And the default currency is "USD"
        And the expense accounts are:
            | Expenses:Groceries           |
            | Expenses:Eat Out & Take Away |
        And the source accounts are:
            | Assets:Cash            |
            | Assets:Bank:Checking   |
            | Liabilities:CreditCard |

    Scenario: A user saves the default settings
        When I save my settings
        Then I see the "Add Transaction" button