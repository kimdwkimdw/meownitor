import assert from 'node:assert/strict';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { catalog } from '../web/cats.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const directory = resolve(process.argv[2] ?? resolve(root, 'dist/web-alpha'));
const hash = data => createHash('sha256').update(data).digest('hex');
const files = readdirSync(directory).sort();
const expected = [
  ...catalog.cats.filter(cat => !cat.bundled).map(cat => `Meownitor-Cat-${cat.id}-v1.zip`),
  'Meownitor-Bundled-Assets-v1.zip', 'Meownitor-Bundled-Assets-v1.zip.sha256',
  'Meownitor-macOS-universal.zip', 'Meownitor-Web-Alpha.zip', 'cat-packs.json', 'SHA256SUMS.txt',
].sort();
assert.deepEqual(files, expected, 'Only the 23 curated files belong in the release');
const checksums = readFileSync(resolve(directory, 'SHA256SUMS.txt'), 'utf8').trim().split('\n').map(line => {
  const match = line.match(/^([a-f0-9]{64})  ([\w.-]+)$/);
  assert.ok(match, `Invalid checksum line: ${line}`);
  return match.slice(1);
});
assert.deepEqual(checksums.map(([, name]) => name).sort(), expected.filter(name => name !== 'SHA256SUMS.txt'));
for (const [digest, name] of checksums) assert.equal(hash(readFileSync(resolve(directory, name))), digest, name);
const names = [...readFileSync(resolve(root, 'Sources/Meownitor/CatPackStore.swift'), 'utf8')
  .match(/static let sequenceNames = \[([\s\S]+?)\]/)[1].matchAll(/"([^\"]+\.webp)"/g)].map(match => match[1]);
assert.equal(names.length, 15);
const listing = name => execFileSync('unzip', ['-Z1', resolve(directory, name)], { encoding: 'utf8' }).trim().split('\n').filter(path => !path.endsWith('/')).sort();
const packs = JSON.parse(readFileSync(resolve(directory, 'cat-packs.json'), 'utf8')).packs;
assert.equal(packs.length, 17);
for (const cat of catalog.cats.filter(cat => !cat.bundled)) {
  const pack = packs.find(pack => pack.id === cat.id);
  const filename = `Meownitor-Cat-${cat.id}-v1.zip`;
  assert.deepEqual(pack, { id: cat.id, version: 1, bytes: cat.bytes, sha256: cat.sha256, url: cat.url });
  const bytes = readFileSync(resolve(directory, filename));
  assert.equal(bytes.length, pack.bytes);
  assert.equal(hash(bytes), pack.sha256);
  assert.deepEqual(listing(filename), names.map(name => `${cat.id}/strips/${name}`).sort());
}
const bundle = listing('Meownitor-Bundled-Assets-v1.zip');
const app = listing('Meownitor-macOS-universal.zip');
assert.equal(bundle.filter(name => name.endsWith('.webp')).length, 60);
assert.equal(app.filter(name => name.endsWith('.webp')).length, 60);
for (const entries of [bundle, app]) {
  assert.ok(entries.every(name => !/\/(raw|intermediate|qa|work)\//.test(name)));
  assert.deepEqual([...new Set(entries.filter(name => name.includes('/Cats/')).map(name => name.split('/Cats/')[1].split('/')[0]))].sort(), ['K01', 'K02', 'K03']);
}
assert.equal(readFileSync(resolve(directory, 'Meownitor-Bundled-Assets-v1.zip.sha256'), 'utf8').trim(), hash(readFileSync(resolve(directory, 'Meownitor-Bundled-Assets-v1.zip'))));
for (const file of listing('Meownitor-Web-Alpha.zip')) {
  assert.ok(!file.includes('..') && !file.startsWith('/'));
  assert.equal(hash(execFileSync('unzip', ['-p', resolve(directory, 'Meownitor-Web-Alpha.zip'), file])), hash(readFileSync(resolve(root, 'web', file))), file);
}
const appCatalog = execFileSync('unzip', ['-p', resolve(directory, 'Meownitor-macOS-universal.zip'), 'Meownitor.app/Contents/Resources/cat-packs.json']);
assert.deepEqual(JSON.parse(appCatalog), { version: 1, packs });
console.log(`PASS: ${files.length} release assets, all checksums, 17 exact pack file sets, 60 bundled strips, embedded catalog, and website contents (${Math.round(files.reduce((sum, name) => sum + statSync(resolve(directory, name)).size, 0) / 1048576)} MiB).`);
