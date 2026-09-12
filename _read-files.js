const fs = require('fs');
const path = require('path');

const files = [
  'postgres-rendered.yaml',
  'templates/infrastructure/postgres.yaml'
];

for (const f of files) {
  const fullPath = path.join(__dirname, f);
  try {
    const content = fs.readFileSync(fullPath, 'utf8');
    console.log(`\n=== FILE: ${f} (${content.length} bytes, ${content.split('\n').length} lines) ===`);
    console.log(content);
  } catch (e) {
    console.error(`Error reading ${f}: ${e.message}`);
  }
}
