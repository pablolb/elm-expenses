Feature: Pagination should be automatic when users scroll down

    Scenario: A user with many, many transactions
        Given I have saved the default settings
        And I have 200 test transactions with description Transaction1, Transaction2...
        Then I see 50 transactions
        When I scroll to the bottom
        Then I see 100 transactions
        And no transaction is repeated

    Scenario: A user with not many transactions
        Given I have saved the default settings
        And I have 39 test transactions with description Transaction1, Transaction2...
        Then I see 39 transactions
        When I scroll to the bottom
        Then I see 39 transactions
        And no transaction is repeated

    Scenario: A user with exactly two pages
        Given I have saved the default settings
        And I have 200 test transactions with description Transaction1, Transaction2...
        Then I see 50 transactions
        When I scroll to the bottom
        Then I see 100 transactions
        When I scroll to the bottom
        Then I see 100 transactions
        And no transaction is repeated