const fs = require('fs');
const path = require('path');

const fpath = path.join(__dirname, 'templates/infrastructure/postgres.yaml');
const content = fs.readFileSync(fpath, 'utf8');
console.log(content);
