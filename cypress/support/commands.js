Cypress.Commands.add(
    'createDefaultSettings',
    () => cy.window().its('ElmExpenses').then(e => e.saveSettings({
        version: "",
        defaultCurrency: "USD",
        destinationAccounts: [ "Expenses:Groceries", "Expenses:Eat Out & Take Away" ],
        sourceAccounts: [ "Assets:Cash", "Assets:Bank:Checking", "Liabilities:CreditCard" ]
    }))
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
    'addTransaction',
    (txnInput) => cy.window()
        .its('ElmExpenses')
        .then(
            ElmExpenses => ElmExpenses.putTransaction(txnInput)
        )
)