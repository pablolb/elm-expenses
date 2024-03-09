Feature: Users with no transactions are presented a different screen

    Background: A user who has chosen his default settings
        Given I have saved the default settings

    Scenario: A user with no transactions sees two buttons
        Then I see "Welcome to Elm Expenses!"
        And I see the "Import Sample" button
        And I see the "Add Transaction" button

    Scenario: A user can import sample with one click
        When I click the "Import Sample" button
        Then I see "Holiday travel expenses"

    Scenario: A user navigate to the Add Transaction form
        When I click the "Add Transaction" button
        Then I see the "Submit" button
