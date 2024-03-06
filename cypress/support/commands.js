Cypress.Commands.add(
    'importSampleData',
    () => cy.window().its('ElmExpenses').then(e => e.importSampleData())
)

Cypress.Commands.add(
    'deleteIndexedDB',
    () => cy.window()
        .its('indexedDB')
        .then(
            indexedDB => indexedDB.deleteDatabase('_pouch_elm_expenses_local')
        )
)

Cypress.Commands.add(
    'addTransaction',
    (txnInput) => cy.window()
        .its('ElmExpenses')
        .then(
            ElmExpenses => ElmExpenses.putTransaction(txnInput)
        )
)