const { Given, Then } = require("@badeball/cypress-cucumber-preprocessor")

const sources = ["Assets:Cash", "Liabilities:CreditCard"]
const destinations = ["Expenses:Groceries", "Expenses:Eat Out & Take Away"]

function random(arr) {
    const randomIndex = Math.floor(Math.random() * arr.length)
    return arr[randomIndex]
}

function buildRandomTransaction(n, date) {
    const amount = 50 + Math.floor(Math.random() * 4000);
    return {
        id: "",
        version: "",
        date: date.toISOString().substr(0,10),
        description: `Transaction ${n}`,
        destination: {
            currency: "USD",
            account: random(destinations),
            amount,
        },
        source: {
            currency: "USD",
            account: random(sources),
            amount: -1 * amount
        }
    };
}

Given('I have {int} test transactions with description Transaction1, Transaction2...', (targetCount) => {
    const perDay = 3
    const transactions = []
    const today = new Date()
    for (let i = 0; i < targetCount; i++) {
        if (i % perDay === 0) {
            today.setDate(today.getDate() + 1)
        }
        transactions.push(buildRandomTransaction(i + 1, today))
    }
    return cy.saveTransactions(transactions).then(() => cy.sendTransactionsToElm())
})

Then('I see {int} transactions', number => {
    cy.get('div').filter('.txn-description').should('have.lengthOf', number)
})

Then('no transaction is repeated', () => {
    cy.get('div').filter('.txn-description').then(($el) => {
        const descriptions = new Set()
        $el.each((_, el) => descriptions.add(el.innerText))
        assert.equal($el.length, descriptions.size)
    });
})