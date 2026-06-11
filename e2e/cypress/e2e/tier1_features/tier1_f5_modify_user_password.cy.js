describe('F5: Modify User Password', () => {
  const backendUrl = 'http://localhost:8081';
  let adminToken = '';
  let user1Id = '';
  let user2Id = '';

  const suffix = Date.now();
  const adminEmail = `admin_f5_${suffix}@test.com`;
  const user1Email = `user1_f5_${suffix}@test.com`;
  const user2Email = `user2_f5_${suffix}@test.com`;

  const adminPassword = 'password123';
  const user1OldPassword = 'oldPassword1';
  const user2OldPassword = 'oldPassword2';
  
  const user1NewPassword = 'newPassword1';
  const user2NewPassword = 'newPassword2';
  const user1NewPasswordV2 = 'newPassword1_v2';

  before(() => {
    // 1. Register an admin user
    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/register`,
      body: {
        email: adminEmail,
        password: adminPassword,
        name: 'Admin F5'
      },
      failOnStatusCode: false
    });

    // 2. Promote admin user in DB via cy.exec
    cy.exec(`docker exec time2wish-postgres psql -U time2wish_user -d time2wish -c "UPDATE users SET role = 'ROLE_ADMIN' WHERE email = '${adminEmail}';"`, { failOnNonZeroExit: false });

    // 3. Register standard users
    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/register`,
      body: {
        email: user1Email,
        password: user1OldPassword,
        name: 'User One F5'
      },
      failOnStatusCode: false
    });

    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/register`,
      body: {
        email: user2Email,
        password: user2OldPassword,
        name: 'User Two F5'
      },
      failOnStatusCode: false
    });

    // 4. Login admin to get JWT token
    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/login`,
      body: {
        email: adminEmail,
        password: adminPassword
      }
    }).then((response) => {
      expect(response.status).to.eq(200);
      adminToken = response.body.token || response.body.accessToken || response.body;

      // 5. Get user IDs
      cy.request({
        method: 'GET',
        url: `${backendUrl}/api/admin/users`,
        headers: {
          Authorization: `Bearer ${adminToken}`
        }
      }).then((res) => {
        expect(res.status).to.eq(200);
        const users = res.body;
        const u1 = users.find(u => u.email === user1Email);
        const u2 = users.find(u => u.email === user2Email);
        
        expect(u1).to.not.be.undefined;
        expect(u2).to.not.be.undefined;
        
        user1Id = u1.id;
        user2Id = u2.id;
      });
    });
  });

  it('TC1: Admin successfully updates a user\'s password via the API, receiving a 200/204 response', () => {
    cy.request({
      method: 'PUT',
      url: `${backendUrl}/api/admin/users/${user1Id}/password`,
      headers: {
        Authorization: `Bearer ${adminToken}`
      },
      body: {
        newPassword: user1NewPassword
      }
    }).then((response) => {
      expect([200, 204]).to.include(response.status);
    });
  });

  it('TC2: The user can successfully log in using the newly updated password', () => {
    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/login`,
      body: {
        email: user1Email,
        password: user1NewPassword
      }
    }).then((response) => {
      expect(response.status).to.eq(200);
    });
  });

  it('TC3: The user is correctly denied access (400/401) when attempting to log in with their old password', () => {
    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/login`,
      body: {
        email: user1Email,
        password: user1OldPassword
      },
      failOnStatusCode: false
    }).then((response) => {
      expect([400, 401, 403]).to.include(response.status);
    });
  });

  it('TC4: Admin can sequentially update the password of a second, different user successfully', () => {
    cy.request({
      method: 'PUT',
      url: `${backendUrl}/api/admin/users/${user2Id}/password`,
      headers: {
        Authorization: `Bearer ${adminToken}`
      },
      body: {
        newPassword: user2NewPassword
      }
    }).then((response) => {
      expect([200, 204]).to.include(response.status);
    });

    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/login`,
      body: {
        email: user2Email,
        password: user2NewPassword
      }
    }).then((response) => {
      expect(response.status).to.eq(200);
    });
  });

  it('TC5: Admin can change the same user\'s password multiple times, and the user can successfully log in with the latest password', () => {
    cy.request({
      method: 'PUT',
      url: `${backendUrl}/api/admin/users/${user1Id}/password`,
      headers: {
        Authorization: `Bearer ${adminToken}`
      },
      body: {
        newPassword: user1NewPasswordV2
      }
    }).then((response) => {
      expect([200, 204]).to.include(response.status);
    });

    cy.request({
      method: 'POST',
      url: `${backendUrl}/api/auth/login`,
      body: {
        email: user1Email,
        password: user1NewPasswordV2
      }
    }).then((response) => {
      expect(response.status).to.eq(200);
    });
  });
});
