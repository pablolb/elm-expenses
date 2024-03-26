Cypress.Commands.add(
    'createDefaultSettings',
    (password = null) => cy.window().its('ElmExpenses').then(e => e.saveSettings({
        version: "",
        defaultCurrency: "USD",
        destinationAccounts: [ "Expenses:Groceries", "Expenses:Eat Out & Take Away" ],
        sourceAccounts: [ "Assets:Cash", "Assets:Bank:Checking", "Liabilities:CreditCard" ]
    }, password))
)

Cypress.Commands.add(
    'importSampleData',
    () => cy.window().its('ElmExpenses').then(e => e.importSampleData())
)

Cypress.Commands.add(
    'deleteAllData',
    () => cy.window().its('ElmExpenses').then(e => e.deleteAllData())
)

Cypress.Commands.add(
    'sendTransactionsToElm',
    () => cy.window().its('ElmExpenses').then(e => e.sendTransactionsToElm())
)

Cypress.Commands.add(
    'addTransaction',
    (txnInput) => {
        cy.window()
        .its('ElmExpenses')
        .then(
            ElmExpenses => ElmExpenses.saveTransaction({
                id: "",
                version: "",
                date: txnInput.date,
                description: txnInput.description,
                destination: {
                  account: txnInput.destination,
                  currency: txnInput.currency,
                  amount: txnInput.amount
                },
                source: {
                  account: txnInput.source,
                  currency: txnInput.currency,
                  amount: -1 * txnInput.amount
                }
              })
        )
    }
)

Cypress.Commands.add(
    'saveTransactions',
    (transactions) => {
        cy.window()
        .its('ElmExpenses')
        .then(
            ElmExpenses => ElmExpenses.saveTransactions(transactions)
        )
    }
)

Cypress.Commands.add(
    'readRawDataFromDb',
    (name) => cy.window().its('ElmExpenses').then(e => e.readRawDataFromDb(name))
)