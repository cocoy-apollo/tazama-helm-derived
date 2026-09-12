const fs = require('fs');
const path = require('path');

// Read the postgres template
const templatePath = path.join(__dirname, 'templates/infrastructure/postgres.yaml');
const templateContent = fs.readFileSync(templatePath, 'utf8');

// Read the rendered output
const renderedPath = path.join(__dirname, 'postgres-rendered.yaml');
const renderedContent = fs.readFileSync(renderedPath, 'utf8');

// Read the values files
const valuesFiles = [
  'values.yaml',
  'values-internal.yaml',
  'values-internal-updated.yaml',
  'values-internal-additions.yaml',
  'values-external-db.yaml'
];

console.log('=== TEMPLATE (first 50 lines) ===');
console.log(templateContent.split('\n').slice(0, 50).join('\n'));

console.log('\n=== RENDERED (first 50 lines) ===');
console.log(renderedContent.split('\n').slice(0, 50).join('\n'));

// Look for key differences
console.log('\n=== KEY DIFFERENCES TO INVESTIGATE ===');

// 1. Check volume mount path in template
const templateMountMatch = templateContent.match(/mountPath:\s*([^#\n]+)/g);
if (templateMountMatch) {
  console.log('Template mountPaths:', templateMountMatch.map(m => m.trim()));
}

// 2. Check volume name in template  
const templateVolumeMatch = templateContent.match(/name:\s*(postgres-[\w-]+)/g);
if (templateVolumeMatch) {
  console.log('Template volume refs:', templateVolumeMatch.map(m => m.trim()));
}

// 3. Check storageClassName in template
const templateStorage = templateContent.match(/storageClassName:\s*([^#\n]+)/g);
if (templateStorage) {
  console.log('Template storageClassName:', templateStorage.map(s => s.trim()));
}

// 4. Check init script configmap in template
const templateConfigMap = templateContent.match(/configMap:\s*\{\n\s+name:\s*postgres-[\w-]+/g);
if (templateConfigMap) {
  console.log('Template ConfigMap refs:', templateConfigMap);
}

// 5. Check PGDATA in template
const templatePGData = templateContent.match(/PGDATA/g);
if (templatePGData) {
  console.log('Template has PGDATA env var');
} else {
  console.log('Template does NOT have PGDATA env var');
}

// 6. Check POSTGRES_DB in template
const templatePostgresDB = templateContent.match(/POSTGRES_DB/g);
if (templatePostgresDB) {
  console.log('Template has POSTGRES_DB env var');
} else {
  console.log('Template does NOT have POSTGRES_DB env var');
}

// 7. Check emptyDir mounts in template
const templateEmptyDir = templateContent.match(/emptyDir:\s*\{\}/g);
if (templateEmptyDir) {
  console.log('Template has emptyDir mounts:', templateEmptyDir.length);
} else {
  console.log('Template has NO emptyDir mounts');
}

// 8. Check readOnlyRootFilesystem in template
const templateReadOnly = templateContent.match(/readOnlyRootFilesystem:\s*(\w+)/g);
if (templateReadOnly) {
  console.log('Template readOnlyRootFilesystem:', templateReadOnly.map(r => r.trim()));
}

// Compare rendered values
console.log('\n=== RENDERED VALUES ===');
const renderedMounts = renderedContent.match(/mountPath:\s*([^#\n]+)/g);
if (renderedMounts) {
  console.log('Rendered mountPaths:', renderedMounts.map(m => m.trim()));
}

const renderedVolumes = renderedContent.match(/name:\s*(postgres-[\w-]+)/g);
if (renderedVolumes) {
  console.log('Rendered volume refs:', renderedVolumes.map(m => m.trim()));
}

const renderedStorage = renderedContent.match(/storageClassName:\s*([^#\n]+)/g);
if (renderedStorage) {
  console.log('Rendered storageClassName:', renderedStorage.map(s => s.trim()));
}

const renderedConfigMap = renderedContent.match(/configMap:\s*\{\n\s+name:\s*postgres-[\w-]+/g);
if (renderedConfigMap) {
  console.log('Rendered ConfigMap refs:', renderedConfigMap);
}

const renderedPGData = renderedContent.match(/PGDATA/g);
if (renderedPGData) {
  console.log('Rendered has PGDATA env var');
} else {
  console.log('Rendered does NOT have PGDATA env var');
}

const renderedPostgresDB = renderedContent.match(/POSTGRES_DB/g);
if (renderedPostgresDB) {
  console.log('Rendered has POSTGRES_DB env var');
} else {
  console.log('Rendered does NOT have POSTGRES_DB env var');
}

const renderedEmptyDir = renderedContent.match(/emptyDir:\s*\{\}/g);
if (renderedEmptyDir) {
  console.log('Rendered has emptyDir mounts:', renderedEmptyDir.length);
} else {
  console.log('Rendered has NO emptyDir mounts');
}

console.log('\n=== DONE ===');
