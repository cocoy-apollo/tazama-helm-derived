import { readFileSync, writeFileSync } from 'fs';

const filePath = 'values-internal.yaml';
const content = readFileSync(filePath, 'utf-8');

// Split into lines
const lines = content.split('\n');
let inRulesDefaults = false;
let braceDepth = 0;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  const trimmed = line.trim();
  
  // Start of rulesDefaults block
  if (trimmed === 'rulesDefaults:') {
    inRulesDefaults = true;
    continue;
  }
  
  // End of rulesDefaults block (next top-level key)
  if (inRulesDefaults && !line.startsWith(' ') && !line.startsWith('\t') && line !== '' && !line.startsWith('\r')) {
    inRulesDefaults = false;
  }
  
  // If in rulesDefaults block, check for memory lines under resources
  if (inRulesDefaults) {
    // Check context: is memory in a resources block?
    // Resources block is at 2 space indent, requests/limits at 4, memory at 6
    const spaces = line.search(/\S/);
    
    // memory line should be at 6-space indent (or 6+2=8 if including \r prefix)
    if (spaces >= 6 && spaces <= 8 && line.includes('memory:') && !line.includes('maxmemory')) {
      // Replace 512Mi and 1Gi with 2Gi
      if (line.includes('"512Mi"') || line.includes('"1Gi"')) {
        lines[i] = line.replace(/"512Mi"/g, '"2Gi"').replace(/"1Gi"/g, '"2Gi"');
        console.log(`Line ${i + 1}: Updated memory value`);
      }
    }
  }
}

const newContent = lines.join('\n');
writeFileSync(filePath, newContent, 'utf-8');
console.log('Done');
