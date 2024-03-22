const { Given, When, Then } = require("@badeball/cypress-cucumber-preprocessor")


Given('I reload the app', () => {
    cy.visit('/')
})


Given("I have saved the default settings", () => {
    cy.createDefaultSettings()
})

Given('an encrypted app with password {string}' , (password) => {
    cy.createDefaultSettings(password)
})

Given(/^I have saved the following transactions:$/, table => {
    for (const txn of table.hashes()) {
        txn.amount = parseInt(txn.amount)
        cy.addTransaction(txn)
    }
    cy.sendTransactionsToElm();
})

When("I click on {string}", text => cy.contains(text).click())

When("I go to settings", () => {
    cy.get('[data-cy="settings"]').click()
})

When("I go to add a transaction", () => cy.get('[data-cy="add-transaction"]').click())

When('I enter the date {string}', date => {
    cy.get('[data-cy="date"]').clear().type(date)
})

When('I enter the description {string}', description => {
    cy.get('[data-cy="description"]').clear().type(description)
})

When('I enter the amount {string}', amount => {
    cy.get('[data-cy="amount"]').clear().type(amount)
})

When('I select the expense account {string}', account => {
    cy.get('[data-cy="destination"]').select(account)
})

When('I select the source account {string}', account => {
    cy.get('[data-cy="source"]').select(account)
})

When('I save the transaction', () => cy.get('[data-cy="submit"]').click())
When('I click the "Add Transaction" button', () => cy.get('[data-cy="add-transaction"]').click())
When('I click the "Import Sample" button', () => cy.get('[data-cy="import-sample"]').click())
When('I click the "Delete All Data" button', () => cy.get('[data-cy="delete-all-data"]').click())
When('I click the "Delete" button', () => cy.get('[data-cy="delete"]').click())
When('I answer "yes" in the confirmation message', () => cy.get('[data-cy="confirm-modal"]').click())
When('I answer "no" in the confirmation message', () => cy.get('[data-cy="cancel-modal"]').click())

When('I enter the password {string}', password => {
    cy.get('[data-cy="current-password"]').clear().type(password)
})
When('I click the "Open" button', () => cy.get('[data-cy="open"]').click())

Then('the date is {string}', text => cy.get('[data-cy="date"]').should('have.value', text))
Then('the description is {string}', text => cy.get('[data-cy="description"]').should('have.value', text))
Then('the selected expense account is {string}', account => {
    cy.get('[data-cy="destination"]').should('have.value', account)
    cy.get('[data-cy="destination"]').find('option:selected').should('have.text', account)
})
Then('the selected source account is {string}', account => {
    cy.get('[data-cy="source"]').should('have.value', account)
    cy.get('[data-cy="source"]').find('option:selected').should('have.text', account)
})
Then('the amount is {string}', text => cy.get('[data-cy="amount"]').should('have.value', text))



Then('I see {string}', text => cy.contains(text).should('be.visible'))
Then('I should not see {string}', text => cy.contains(text).should('not.exist'))
Then('I see the "Submit" button', () => cy.get('[data-cy="submit"]').should('exist'))
Then('I see the "Add Transaction" button', () => cy.get('[data-cy="add-transaction"]').should('exist'))
Then('I see the "Cancel" button', () => cy.get('[data-cy="cancel"]').should('exist'))
Then('I see the "Import Sample" button', () => cy.get('[data-cy="import-sample"]').should('exist'))
Then('I see the "Delete All Data" button', () => cy.get('[data-cy="delete-all-data"]').should('exist'))


When('I set the default currency to "{word}"', currency => {
    cy.get('[data-cy="default-currency"]').clear().type(currency)
})

When(/^I set the expense accounts to:$/, table => {
    const accounts = table.raw().join("\n")
    cy.get('[data-cy="destination-accounts"]').clear().type(accounts)
 })

When(/^I set the source accounts to:$/, table => {
    const accounts = table.raw().join("\n")
    cy.get('[data-cy="source-accounts"]').clear().type(accounts)
})

When('I set the current password to {string}', password => {
    cy.get('[data-cy="current-password"]').clear().type(password)
})

When('I set the new password to {string}', password => {
    cy.get('[data-cy="new-password"]').clear().type(password)
})

When('I set the new password confirmation to {string}', password => {
    cy.get('[data-cy="new-password-confirm"]').clear().type(password)
})

When("I save my settings", () => cy.get('[data-cy="save"]').click())

Then('the default currency is "{word}"', currency => cy.get('[data-cy="default-currency"]').should('have.value', currency))

Then(/^the expense accounts are:$/, table => {
    const expected = table.raw().join("\n")
    cy.get('[data-cy="destination-accounts"]').should('have.value', expected)
})

Then(/^the source accounts are:$/, table => {
    const expected = table.raw().join("\n")
    cy.get('[data-cy="source-accounts"]').should('have.value', expected)
})

Then("I see an error message {string}", text => {
    cy.get('div.error.message').children().should('contain.text', text)
})