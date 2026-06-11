describe('F1 Admin Auth (RBAC)', () => {

  const setupMockLogin = (role) => {
    // Prevent auto-login on startup
    cy.intercept('POST', '**/api/auth/refresh', { statusCode: 401 }).as('refreshFail');
    
    // Intercept the login request
    cy.intercept('POST', '**/api/auth/login', {
      statusCode: 200,
      body: {
        token: 'fake-jwt-token',
        id: 1,
        email: 'test@example.com',
        fullName: 'Test User',
        roles: [role]
      }
    }).as('login');
  };

  const performLogin = () => {
    cy.visit('/login');
    cy.wait('@refreshFail');
    
    cy.get('input#login-email').type('test@example.com');
    cy.get('input#login-password').type('password');
    cy.get('button[type="submit"]').click();
    cy.wait('@login');
    cy.url().should('include', '/dashboard');
  };

  beforeEach(() => {
    // Clear storage before each test
    cy.clearLocalStorage();
    cy.clearCookies();
  });

  it('Test Case 1: Admin Authorization (Happy Path)', () => {
    setupMockLogin('ROLE_ADMIN');
    performLogin();
    
    // Once logged in, mock refresh to succeed for subsequent navigation
    cy.intercept('POST', '**/api/auth/refresh', {
      statusCode: 200,
      body: {
        token: 'fake-jwt-token',
        id: 1,
        email: 'test@example.com',
        fullName: 'Test User',
        roles: ['ROLE_ADMIN']
      }
    }).as('refreshSuccess');
    
    cy.visit('/admin');
    cy.url().should('include', '/admin/dashboard');
    cy.get('.admin-layout').should('be.visible');
  });

  it('Test Case 2: Standard User Access Blocked (Negative)', () => {
    setupMockLogin('ROLE_USER');
    performLogin();
    
    // Mock refresh to succeed as standard user
    cy.intercept('POST', '**/api/auth/refresh', {
      statusCode: 200,
      body: {
        token: 'fake-jwt-token',
        id: 1,
        email: 'test@example.com',
        fullName: 'Test User',
        roles: ['ROLE_USER']
      }
    }).as('refreshSuccess');
    
    cy.visit('/admin');
    // The admin guard redirects to dashboard
    cy.url().should('include', '/dashboard');
    cy.url().should('not.include', '/admin');
  });

  it('Test Case 3: Unauthenticated Access Blocked (Negative)', () => {
    // Force refresh to fail so user is unauthenticated
    cy.intercept('POST', '**/api/auth/refresh', { statusCode: 401 }).as('refreshFail');
    
    cy.visit('/admin');
    cy.wait('@refreshFail');
    
    // The auth guard redirects to login
    cy.url().should('include', '/login');
  });

  it('Test Case 4: RBAC UI Element Visibility', () => {
    // Step 1: Admin login
    setupMockLogin('ROLE_ADMIN');
    performLogin();
    
    // Verify admin link is present in UI
    cy.get('a.admin-btn').should('be.visible');
    
    // Clear session for next user
    cy.clearLocalStorage();
    cy.clearCookies();
    
    // Step 2: Standard User login
    setupMockLogin('ROLE_USER');
    performLogin();
    
    // Verify admin link is not present
    cy.get('a.admin-btn').should('not.exist');
  });

  it('Test Case 5: Session Revocation / Logout Security', () => {
    setupMockLogin('ROLE_ADMIN');
    performLogin();
    
    cy.intercept('POST', '**/api/auth/refresh', {
      statusCode: 200,
      body: {
        token: 'fake-jwt-token',
        id: 1,
        email: 'test@example.com',
        fullName: 'Test User',
        roles: ['ROLE_ADMIN']
      }
    }).as('refreshSuccess');
    
    cy.visit('/admin');
    cy.url().should('include', '/admin/dashboard');
    cy.get('.admin-layout').should('be.visible');
    
    // Intercept logout and subsequent refresh
    cy.intercept('POST', '**/api/auth/logout', { statusCode: 200 }).as('logout');
    cy.intercept('POST', '**/api/auth/refresh', { statusCode: 401 }).as('refreshFailLogout');
    
    // Click logout
    cy.get('.logout-btn').click();
    cy.wait('@logout');
    
    // Should be redirected to login
    cy.url().should('include', '/login');
    
    // Try to visit /admin again
    cy.visit('/admin');
    cy.wait('@refreshFailLogout');
    cy.url().should('include', '/login');
    cy.url().should('not.include', '/admin');
  });
});
