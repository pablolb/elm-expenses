const { Given, When, Then } = require("@badeball/cypress-cucumber-preprocessor")

When('I toggle the advanced mode', () => {
    cy.get('[data-cy="toggle-advanced"]').click()
})

When('I enter the destination account {string}', account => {
    cy.get('[data-cy="destination"]').clear().type(account)
})

When('I enter the source account {string}', account => {
    cy.get('[data-cy="source"]').clear().type(account)
})

When('I enter the currency {string}', account => {
    cy.get('[data-cy="currency"]').clear().type(account)
})

Then('the advanced mode toggle is on', () => {
    cy.get('[data-cy="toggle-advanced"]').should('be.checked')
})

Then('the advanced mode toggle is off', () => {
    cy.get('[data-cy="toggle-advanced"]').should('not.be.checked')
})

Then("I don't see the expense account dropdown", () => {
    cy.get('select[data-cy="destination"]').should('not.exist')
})

Then("I don't see the source account dropdown", () => {
    cy.get('select[data-cy="source"]').should('not.exist')
})

Then('I see a destination account text input', () => {
    cy.get('input[data-cy="destination"]').should('be.visible')
})

Then('I see a source account text input', () => {
    cy.get('input[data-cy="source"]').should('be.visible')
})

Then('I see a currency text input', () => {
    cy.get('input[data-cy="source"]').should('be.visible')
})

Then('the destination account is {string}', (account) => {
    cy.get('input[data-cy="destination"]').should('have.value', account)
})

Then('the source account is {string}', (account) => {
    cy.get('input[data-cy="source"]').should('have.value', account)
})