Feature: Users should be able encrypt their data

    Scenario: Encrypting on first run
        When I set the new password to "secret password"
        When I set the new password confirmation to "secret password"
        And I save my settings
        When I reload the app
        Then I see "Enter password"

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

    Scenario: Encrypting an unencrypted application
        Given I have saved the default settings
        And I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        When I go to settings
        And I set the new password to "secret password"
        And I set the new password confirmation to "secret password"
        And I save my settings
        # We need to give time for the settings to be persisted - replace later with "Then I am in transaction list"
        Then I see "Pizza"
        When I reload the app
        Then I see "Enter password"
        And there are no unencrypted documents in PouchDB named "elm_expenses_local"
        And there are no unencrypted documents in PouchDB named "elm_expenses_settings"
        And there is an encrypted document in PouchDB named "elm_expenses_local" with ID starting with "2024-03-01"

    Scenario: Decrypting an encrypted application
        Given an encrypted app with password "my cool password"
        And I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        When I reload the app
        And I enter the password "my cool password"
        And I click the "Open" button
        And I go to settings
        And I set the current password to "my cool password"
        And I save my settings
        # We need to give time for the settings to be persisted - replace later with "Then I am in transaction list"
        Then I see "Pizza"
        When I reload the app
        Then I see "Pizza"
        And there are no encrypted documents in PouchDB named "elm_expenses_local"
        And there are no encrypted documents in PouchDB named "elm_expenses_settings"
        And there is an unencrypted document in PouchDB named "elm_expenses_local" with ID starting with "2024-03-01"

    Scenario: Encrypting an encrypted application with a new password
        Given an encrypted app with password "my old password"
        And I have saved the following transactions:
            | date       | description | destination                  | source      | amount | currency |
            | 2024-03-01 | Pizza       | Expenses:Eat Out & Take Away | Assets:Cash | 3999   | USD      |
        When I reload the app
        And I enter the password "my old password"
        And I click the "Open" button
        And I go to settings
        And I set the current password to "my old password"
        And I set the new password to "pizza"
        And I set the new password confirmation to "pizza"
        And I save my settings
        # We need to give time for the settings to be persisted - replace later with "Then I am in transaction list"
        Then I see "Pizza"
        When I reload the app
        And I enter the password "my old password"
        And I click the "Open" button
        Then I see an error message "Invalid password"
        And there are no unencrypted documents in PouchDB named "elm_expenses_local"
        And there are no unencrypted documents in PouchDB named "elm_expenses_settings"
        And there is an encrypted document in PouchDB named "elm_expenses_local" with ID starting with "2024-03-01"



