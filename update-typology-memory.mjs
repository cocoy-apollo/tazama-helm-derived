import fs from 'fs';

const filePath = './values-internal.yaml';
let content = fs.readFileSync(filePath, 'utf-8');

// Define the typologyDefaults section to insert
const typologyDefaultsSection = `
# =============================================================================
# =============================================================================
# TYPOLOGY DEFAULTS
# Resource limits and settings for typology pods (not rules)
# =============================================================================

typologyDefaults:
  replicas: 1
  waitForSchema: true
  imagePullPolicy: IfNotPresent
  resources:
    requests:
      cpu: "100m"
      memory: "2Gi"
    limits:
      cpu: "500m"
      memory: "2Gi"
  logLevel: "info"
  nodeEnv: "production"

`;

// Insert typologyDefaults BEFORE rulesDefaults
if (content.includes('rulesDefaults:') && !content.includes('typologyDefaults:')) {
  content = content.replace('rulesDefaults:', typologyDefaultsSection + 'rulesDefaults:');
  fs.writeFileSync(filePath, content, 'utf-8');
  console.log('Added typologyDefaults section with 2Gi memory before rulesDefaults');
} else if (content.includes('typologyDefaults:')) {
  console.log('typologyDefaults section already exists');
} else {
  console.log('Could not find rulesDefaults section');
}
