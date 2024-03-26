const { Then } = require("@badeball/cypress-cucumber-preprocessor")

Then('there are no unencrypted documents in PouchDB named {string}', (name) => {
    cy.readRawDataFromDb(name).then(docs => {
        const unencrypted = docs.filter(d => d.crypt === undefined);
        if (unencrypted.length > 0) {
            throw new Error("Found at least one document unencrypted: " + JSON.stringify(unencrypted[0]));
        }
    });
})

Then('there is an encrypted document in PouchDB named {string} with ID starting with {string}', (name, idPrefix) => {
    cy.readRawDataFromDb(name).then(docs => {
        console.log(docs)
        if (docs.some(d => d.crypt !== undefined && d._id.startsWith(idPrefix))) {
            return;
        }
        throw new Error(`No encrypted document with ID starting with "${idPrefix}" found`);
    });
})

Then('there are no encrypted documents in PouchDB named {string}', (name) => {
    cy.readRawDataFromDb(name).then(docs => {
        const encrypted = docs.filter(d => d.crypt !== undefined);
        if (encrypted.length > 0) {
            throw new Error("Found at least one document encrypted: " + JSON.stringify(unencrypted[0]));
        }
    });
})

Then('there is an unencrypted document in PouchDB named {string} with ID starting with {string}', (name, idPrefix) => {
    cy.readRawDataFromDb(name).then(docs => {
        if (docs.some(d => d.crypt === undefined && d._id.startsWith(idPrefix))) {
            return;
        }
        throw new Error(`No unencrypted document with ID starting with "${idPrefix}" found`);
    });
})

