describe('Editing transaction with custom accounts', () => {
    it('should render the correct expense/source drop-downs', () => {

        cy.visit('/')

        cy.addTransaction({
            date: "2024-02-29",
            description: "Fill-up tank",
            destination: "Expenses:Auto:Gas",
            source: "Assets:PayPal",
            amount: 1999,
            currency: "USD"
          })

        cy.contains('Fill-up tank').click()
        
        cy.get('[data-cy="destination"]').should('have.value', 'Expenses:Auto:Gas')
        cy.get('[data-cy="destination"]').find('option:selected').should('have.text', 'Expenses:Auto:Gas')

        cy.get('[data-cy="source"]').should('have.value', 'Assets:PayPal')
        cy.get('[data-cy="source"]').find('option:selected').should('have.text', 'Assets:PayPal');
    })
})