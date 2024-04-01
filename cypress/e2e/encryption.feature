Feature: Users should be able encrypt their data

    Scenario: Encrypting is suggested by default on first run
        Then the use encryption toggle is on
        When I set the new password to "secret password"
        And I set the new password confirmation to "secret password"
        And I save my settings
        When I reload the app
        Then I see "Enter password"

    Scenario: A user can opt-out of encryption
        Then the use encryption toggle is on
        When I toggle use encryption
        Then I should not see "Encryption password"
        When I save my settings
        And I reload the app
        Then I see "New"

    Scenario: A user cannot change encryption setting after choosing encryption
        When I set the new password to "secret password"
        And I set the new password confirmation to "secret password"
        And I save my settings
        And I go to settings
        Then I should not see "Encrypt local database"

    Scenario: A user cannot change encryption setting after opting-out of encryption
        When I toggle use encryption
        And I save my settings
        And I go to settings
        Then I should not see "Encrypt local database"

    Scenario: Opening an encrypted app
        Given an encrypted app with password "my cool password"
        And I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        When I reload the app
        Then I see "Enter password"
        When I enter the password "my cool password"
        And I click the "Open" button
        Then I see "Pizza"

    Scenario: Opening an encrypted app with the wrong password
        Given an encrypted app with password "my cool password"
        When I reload the app
        When I enter the password "wrong password"
        And I click the "Open" button
        Then I see an error message "Invalid password"

    Scenario: Reading encrypted data from PouchDB
        Given an encrypted app with password "my cool password"
        And I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        Then there are no unencrypted documents in PouchDB named "elm_expenses_local"
        And there are no unencrypted documents in PouchDB named "elm_expenses_settings"
        And there is an encrypted document in PouchDB named "elm_expenses_local" with ID starting with "2024-03-01"

    Scenario: Reading unencrypted data from PouchDB
        Given I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        Then there are no encrypted documents in PouchDB named "elm_expenses_local"
        And there are no encrypted documents in PouchDB named "elm_expenses_settings"
        And there is an unencrypted document in PouchDB named "elm_expenses_local" with ID starting with "2024-03-01"
