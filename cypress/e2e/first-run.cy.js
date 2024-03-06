describe('First time running the application', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  it('renders a Welcome message with two buttons', () => {
    cy.get('[data-cy="import"]').should('be.visible')
    cy.get('[data-cy="add-transaction"]').should('be.visible')
  })

  it('imports sample', () => {
    cy.get('[data-cy="import"]').click()
    cy.contains('Gym membership renewal').should('be.visible')
  })

  it('imports renders edit view', () => {
    cy.get('[data-cy="add-transaction"]').click()
    cy.get('[data-cy="submit"]').should('be.visible')
  })
})