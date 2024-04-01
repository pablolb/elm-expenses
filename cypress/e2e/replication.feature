Feature: Users should be able to replicate their local database

    Scenario: Replicating to an empty remote
        Given I have saved the default settings
        And I have saved the following transactions:
            | date       | description  | destination                  | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas            | Assets:PayPal | 1999   | USD      |
            | 2024-03-01 | Pizza        | Expenses:Eat Out & Take Away | Assets:Cash   | 3999   | USD      |
        Then I see "Fill-up tank"
        And the sync icon button is not present
        When I go to settings
        Then the use replication toggle is off
        When I toggle use replication
        Then the use replication toggle is on
        When I set the replication URL to "memory://remotedb"
        And I set the replication username to "any-username"
        And I set the replication password to "any-password"
        And I save my settings
        Then the sync icon button is present
        When I press the sync icon button
        Then I see "Sent: 2"

    Scenario: Replicating an empty DB from a previously synched remote
        Given an empty app but I had previously synched the following transactions:
            | date       | description  | destination                  | source        | amount | currency |
            | 2024-02-29 | Fill-up tank | Expenses:Auto:Gas            | Assets:PayPal | 1999   | USD      |
            | 2024-03-01 | Pizza        | Expenses:Eat Out & Take Away | Assets:Cash   | 3999   | USD      |
        Then I see "Import Sample"
        And I see 0 transactions
        When I press the sync icon button
        Then I see 2 transactions
        And I see "Received: 2"
