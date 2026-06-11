import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import ts from 'typescript';

const basePath = 'd:\\formations_personnelles\\time2wish-ai\\e2e';

function assert(condition, message) {
    if (!condition) {
        console.error(`FAIL: ${message}`);
        process.exit(1);
    }
}

try {
    console.log("1. Verifying Cypress is installed in package.json...");
    const pkgPath = path.join(basePath, 'package.json');
    assert(fs.existsSync(pkgPath), 'package.json missing');
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    assert(pkg.devDependencies && pkg.devDependencies.cypress, 'cypress not in devDependencies');
    assert(pkg.devDependencies && pkg.devDependencies.typescript, 'typescript not in devDependencies');
    console.log("   -> OK");

    console.log("2. Verifying directories exist...");
    const tiers = [
        'tier1_features',
        'tier2_boundaries',
        'tier3_interactions',
        'tier4_scenarios'
    ];
    for (const tier of tiers) {
        const tierPath = path.join(basePath, 'cypress', 'e2e', tier);
        assert(fs.existsSync(tierPath), `Directory missing: ${tierPath}`);
        assert(fs.existsSync(path.join(tierPath, '.keep')), `.keep file missing in ${tierPath}`);
    }
    console.log("   -> OK");

    console.log("3. Verifying cypress.config.ts is syntactically valid and contains configurations...");
    const configPath = path.join(basePath, 'cypress.config.ts');
    assert(fs.existsSync(configPath), 'cypress.config.ts missing');
    const configContent = fs.readFileSync(configPath, 'utf8');
    assert(configContent.includes('baseUrl:'), 'cypress.config.ts missing baseUrl');
    assert(configContent.includes('apiUrl:'), 'cypress.config.ts missing apiUrl');

    // Syntax check using TypeScript compiler API
    const sourceFile = ts.createSourceFile(
        'cypress.config.ts',
        configContent,
        ts.ScriptTarget.Latest,
        true
    );
    
    // Check for parse errors
    const parseDiagnostics = sourceFile.parseDiagnostics;
    if (parseDiagnostics && parseDiagnostics.length > 0) {
        console.error("FAIL: Syntax errors found in cypress.config.ts:");
        parseDiagnostics.forEach(d => {
            console.error(`  - ${d.messageText}`);
        });
        process.exit(1);
    }
    console.log("   -> OK");

    console.log("4. Verifying Cypress binary (npx cypress verify)...");
    try {
        execSync('npx cypress verify', { cwd: basePath, stdio: 'inherit' });
    } catch (e) {
        assert(false, `npx cypress verify failed: ${e.message}`);
    }
    console.log("   -> OK");

    console.log("PASS: M1 Verification successful.");
} catch (err) {
    console.error(`FAIL: Exception during verification: ${err.message}`);
    process.exit(1);
}
