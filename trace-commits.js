const { execSync } = require('child_process');
const path = 'tazama/tazama-helm-derived';

const commits = [
  'e08a441',  // fix-postgres-emptydir-mounts
  'a3e2f7d',  // fix-postgres-mountpath-for-pg18
  '82b56f0',  // fix-postgres-init-db-sql-4dbs
  'HEAD'      // current
];

for (const commit of commits) {
  console.log(`\n=== COMMIT: ${commit} ===`);
  try {
    const out = execSync(`git show ${commit}:templates/infrastructure/postgres.yaml`, { cwd: path, encoding: 'utf8' });
    // Just show key lines
    const lines = out.split('\n');
    for (const line of lines) {
      if (line.includes('mountPath') || 
          line.includes('volumeClaim') || 
          line.includes('PGDATA') || 
          line.includes('POSTGRES_DB') ||
          line.includes('emptyDir') ||
          line.includes('postgres-init') ||
          line.includes('postgres-data') ||
          line.includes('postgres-storage') ||
          line.includes('readOnlyRoot')) {
        console.log(line);
      }
    }
  } catch(e) {
    console.error('Error:', e.message);
  }
}
