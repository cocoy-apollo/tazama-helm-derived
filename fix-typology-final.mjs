import fs from 'fs';

const filePath = './templates/typologies/typologies.yaml';
let content = fs.readFileSync(filePath, 'utf-8');

// Track replacements
let replacements = 0;

// Replace remaining rulesDefaults references with typologyDefaults
const patterns = [
  [/\{\{ \$\.Values\.rulesDefaults\.waitForSchema/g, '{{ $.Values.typologyDefaults.waitForSchema'],
  [/\{\{ \$\.Values\.rulesDefaults\.nodeSelector/g, '{{ $.Values.typologyDefaults.nodeSelector'],
  [/\{\{ \$\.Values\.rulesDefaults\.affinity/g, '{{ $.Values.typologyDefaults.affinity'],
  [/\{\{ \$\.Values\.rulesDefaults\.tolerations/g, '{{ $.Values.typologyDefaults.tolerations']
];

for (const [pattern, replacement] of patterns) {
  const matches = content.match(pattern);
  if (matches) {
    replacements += matches.length;
  }
  content = content.replace(pattern, replacement);
}

if (replacements > 0) {
  fs.writeFileSync(filePath, content, 'utf-8');
  console.log(`Updated ${replacements} remaining references from rulesDefaults to typologyDefaults`);
} else {
  console.log('No remaining rulesDefaults references found');
}
