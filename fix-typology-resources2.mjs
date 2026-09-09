import fs from 'fs';

const filePath = './templates/typologies/typologies.yaml';
let content = fs.readFileSync(filePath, 'utf-8');

// Track replacements
let replacements = 0;

// Replace rulesDefaults.resources with typologyDefaults.resources
const resourcePattern = /\{\{ \$\.Values\.rulesDefaults\.resources/g;
content = content.replace(resourcePattern, (match) => {
  replacements++;
  return '{{ $.Values.typologyDefaults.resources';
});

// Replace other rulesDefaults references with typologyDefaults
const otherPatterns = [
  [/\{\{ \$\.Values\.rulesDefaults\.replicas/g, '{{ $.Values.typologyDefaults.replicas'],
  [/\{\{ \$\.Values\.rulesDefaults\.waitForSchema/g, '{{ $.Values.typologyDefaults.waitForSchema'],
  [/\{\{ \$\.Values\.rulesDefaults\.imagePullPolicy/g, '{{ $.Values.typologyDefaults.imagePullPolicy'],
  [/\{\{ \$\.Values\.rulesDefaults\.nodeSelector/g, '{{ $.Values.typologyDefaults.nodeSelector'],
  [/\{\{ \$\.Values\.rulesDefaults\.affinity/g, '{{ $.Values.typologyDefaults.affinity'],
  [/\{\{ \$\.Values\.rulesDefaults\.tolerations/g, '{{ $.Values.typologyDefaults.tolerations']
];

for (const [pattern, replacement] of otherPatterns) {
  content = content.replace(pattern, (match) => {
    replacements++;
    return replacement;
  });
}

if (replacements > 0) {
  fs.writeFileSync(filePath, content, 'utf-8');
  console.log(`Updated ${replacements} references from rulesDefaults to typologyDefaults in typologies.yaml`);
} else {
  console.log('No rulesDefaults references found in typologies.yaml');
}
