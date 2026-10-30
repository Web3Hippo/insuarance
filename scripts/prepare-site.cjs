const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const output = path.join(root, '_site');
fs.mkdirSync(path.join(output, 'assets'), { recursive: true });
fs.copyFileSync(path.join(root, 'index.html'), path.join(output, 'index.html'));
fs.copyFileSync(path.join(root, 'assets', 'comparison.png'), path.join(output, 'assets', 'comparison.png'));
fs.writeFileSync(path.join(output, '.nojekyll'), '');
console.log('Prepared _site with comparison page and image');
