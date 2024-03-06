describe('CRUD Transactions', () => {

    const isoDate = '2024-03-03'
    const stringDate = '3 Mar 2024'


    beforeEach(() => {
      cy.visit('/')
    })
  
    it('should be able to add transactions', () => {
      cy.get('[data-cy="add-transaction"]').click()

      
      
      cy.get('[data-cy="date"]').type(isoDate)
      cy.get('[data-cy="description"]').type('Pizza')
      cy.get('[data-cy="destination"]').select('Expenses:Eat Out & Take Away')
      cy.get('[data-cy="source"]').select('Assets:Bank:Checking')
      cy.get('[data-cy="amount"]').type('12.99')
      cy.get('[data-cy="submit"]').click()

      
      cy.contains(stringDate).should('be.visible')
      cy.contains('Pizza').should('be.visible')
      cy.contains(':Eat Out & Take Away').should('be.visible')
      cy.contains(':Checking').should('be.visible')
      cy.contains('USD 12.99').should('be.visible')
    })

    it('should be able to edit transactions', () => {
      cy.addTransaction({
        date: "2024-02-29",
        description: "Fill-up tank",
        destination: "Expenses:Auto:Gas",
        source: "Assets:Bank:Checking",
        amount: 1999,
        currency: "USD"
      })

      cy.contains('Fill-up tank').click()
      
      cy.get('[data-cy="date"]').type(isoDate)
      cy.get('[data-cy="description"]').clear().type('Pizza')
      cy.get('[data-cy="destination"]').select('Expenses:Eat Out & Take Away')
      cy.get('[data-cy="source"]').select('Assets:Bank:Checking')
      cy.get('[data-cy="amount"]').clear().type('12.99')
      cy.get('[data-cy="submit"]').click()

      
      cy.contains(stringDate).should('be.visible')
      cy.contains('Pizza').should('be.visible')
      cy.contains(':Eat Out & Take Away').should('be.visible')
      cy.contains(':Checking').should('be.visible')
      cy.contains('USD 12.99').should('be.visible')
    })

    it('should be able to delete transactions', () => {
      cy.addTransaction({
        date: "2024-02-29",
        description: "Fill-up tank",
        destination: "Expenses:Auto:Gas",
        source: "Assets:Bank:Checking",
        amount: 1999,
        currency: "USD"
      })

      cy.contains('Fill-up tank').click()
      cy.get('[data-cy="delete"]').click()
      cy.contains('Fill-up tank').should('not.exist')
    })

  
})
