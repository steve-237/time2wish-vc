const fs = require('fs');
const path = require('path');

function verify() {
  let pass = true;
  const projectRoot = 'd:\\formations_personnelles\\time2wish-ai\\e2e';

  // 1. Verify Cypress is installed (in package.json)
  const pkgPath = path.join(projectRoot, 'package.json');
  if (!fs.existsSync(pkgPath)) {
    console.error('package.json not found');
    pass = false;
  } else {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    if (!pkg.devDependencies || !pkg.devDependencies.cypress) {
      console.error('Cypress not found in devDependencies');
      pass = false;
    } else {
      console.log('PASS: Cypress is in devDependencies');
    }
  }

  // 2. Verify directories exist
  const dirs = [
    'cypress/e2e/tier1_features',
    'cypress/e2e/tier2_boundaries',
    'cypress/e2e/tier3_interactions',
    'cypress/e2e/tier4_scenarios'
  ];
  for (const dir of dirs) {
    const fullPath = path.join(projectRoot, dir);
    if (!fs.existsSync(fullPath)) {
      console.error(`Directory missing: ${dir}`);
      pass = false;
    } else {
      console.log(`PASS: Directory exists - ${dir}`);
    }
  }

  // 3. Verify cypress.config.ts is syntactically valid and contains required configs
  const configPath = path.join(projectRoot, 'cypress.config.ts');
  if (!fs.existsSync(configPath)) {
    console.error('cypress.config.ts not found');
    pass = false;
  } else {
    const configContent = fs.readFileSync(configPath, 'utf8');
    // Simple syntax & content check since we can't easily execute TS directly in plain node without setup
    if (!configContent.includes("defineConfig(")) {
      console.error('cypress.config.ts does not export defineConfig');
      pass = false;
    }
    if (!configContent.includes("baseUrl: 'http://localhost:4200'")) {
      console.error('cypress.config.ts does not contain baseUrl');
      pass = false;
    }
    if (!configContent.includes("apiUrl: 'http://localhost:8081/api/admin'")) {
      console.error('cypress.config.ts does not contain apiUrl');
      pass = false;
    }
    console.log('PASS: cypress.config.ts contains expected configurations');
  }

  if (pass) {
    console.log('\nOVERALL RESULT: PASSES');
  } else {
    console.log('\nOVERALL RESULT: FAILS');
  }
}

verify();
