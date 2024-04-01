const { Given } = require("@badeball/cypress-cucumber-preprocessor")

Given(/^an empty app but I had previously synched the following transactions:$/, table => {
    cy.createReplicationSettings()
    for (const txn of table.hashes()) {
        txn.amount = parseInt(txn.amount)
        cy.addTransaction(txn)
    }
    cy.syncWithRemote()
    cy.deleteDataDb();
})