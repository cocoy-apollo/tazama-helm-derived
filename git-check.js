const { execSync } = require('child_process');
const path = 'tazama/tazama-helm-derived';

console.log('=== GIT LOG for postgres.yaml ===');
try {
  const out = execSync('git log --oneline -20 -- templates/infrastructure/postgres.yaml', { cwd: path, encoding: 'utf8' });
  console.log(out);
} catch(e) {
  console.error('git log error:', e.message);
}

console.log('=== GIT SHOW latest ===');
try {
  const out = execSync('git show HEAD:templates/infrastructure/postgres.yaml', { cwd: path, encoding: 'utf8' });
  console.log(out);
} catch(e) {
  console.error('git show error:', e.message);
}
