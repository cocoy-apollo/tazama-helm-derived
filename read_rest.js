const fs = require('fs');
const path = process.argv[2];
const content = fs.readFileSync(path, 'utf8');
console.log(content.substring(6500));
