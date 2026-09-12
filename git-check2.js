const { execSync } = require('child_process');
const path = 'tazama/tazama-helm-derived';

// Show the fix-postgres-emptydir-mounts commit
console.log('=== GIT SHOW e08a441 (fix-postgres-emptydir-mounts) ===');
try {
  const out = execSync('git show e08a441:templates/infrastructure/postgres.yaml', { cwd: path, encoding: 'utf8' });
  console.log(out);
} catch(e) {
  console.error('Error:', e.message);
}
