const { When } = require("@badeball/cypress-cucumber-preprocessor")
const buildSampleData = require('../../src/SampleData').default

const sample = buildSampleData().map(t => {
    t.id = ""
    t.version = ""
    return t
})

function importJson(json) {
    cy.window()
        .its('ElmExpenses')
        .then(
            ElmExpenses => ElmExpenses.importJson(json)
        )
}

When('I click on "Import Json"', () => {
    cy.get('[data-cy="import-json"]')
})

When('I import the sample JSON file',  () => {
    importJson(JSON.stringify(sample))
})

When('I import a JSON file containing', text => {
    importJson(text)
})