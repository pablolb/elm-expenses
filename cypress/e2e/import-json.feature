Feature: Users should be able import data from JSON files

    Scenario: Importing transactions from valid JSON
        Given I save my settings
        And I go to settings
        And I import the sample JSON file
        Then I see "Dental cleaning"


    Scenario: Importing transactions missing id or version
        Given I save my settings
        And I go to settings
        And I import a JSON file containing
            """json
        [
            {
                "date": "2021-01-10",
                "description": "Utility bill payment",
                "destination": {
                    "account": "Expenses:Utilities",
                    "amount": 6000,
                    "currency": "USD"
                },
                "source": {
                    "account": "Assets:Bank",
                    "amount": -6000,
                    "currency": "USD"
                }
            }
        ]
            """
        Then I see an error message "Error decoding JSON"


