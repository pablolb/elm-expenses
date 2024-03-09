const { Given, When, Then } = require("@badeball/cypress-cucumber-preprocessor")

When('I set the default currency to an empty string', () => {
    cy.get('[data-cy="default-currency"]').clear()
})

When('I set the expense accounts to an empty string', () => {
    cy.get('[data-cy="destination-accounts"]').clear()
})

When('I set the source accounts to an empty string', () => {
    cy.get('[data-cy="source-accounts"]').clear()
})