import assert from 'node:assert/strict';
import { readFileSync, statSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';
import { translations, ui, resolveLanguage, releaseTag, downloadBase } from '../web/content.mjs';
import { catalog } from '../web/cats.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const web = resolve(root, 'web');
const html = readFileSync(resolve(web, 'index.html'), 'utf8');
const keys = [...html.matchAll(/data-i18n(?:-aria)?="([^"]+)"/g)].map(match => match[1]);
for (const language of ['ko', 'ja']) {
  assert.deepEqual(Object.keys(translations[language]).sort(), [...new Set(keys)].sort(), `${language}: translation coverage`);
  assert.ok(Object.values(translations[language]).every(value => typeof value === 'string' && value.length > 0));
  assert.deepEqual(Object.keys(ui[language]).sort(), Object.keys(ui.en).sort());
}
assert.equal(resolveLanguage('ja', 'ko', ['en-US']), 'ja');
assert.equal(resolveLanguage('bad', 'ko', ['en-US']), 'ko');
assert.equal(resolveLanguage(null, null, ['ja-JP', 'en']), 'ja');
assert.equal(resolveLanguage(null, null, ['fr-FR']), 'en');
assert.equal(resolveLanguage('__proto__', 'constructor', []), 'en');
assert.equal(catalog.releaseTag, releaseTag);
assert.equal(catalog.cats.length, 21);
assert.equal(new Set(catalog.cats.map(cat => cat.id)).size, 21);
assert.deepEqual(catalog.cats.filter(cat => cat.bundled).map(cat => cat.id), ['elsa', 'K01', 'K02', 'K03']);
const swiftProfiles = readFileSync(resolve(root, 'Sources/Meownitor/CatProfile.swift'), 'utf8');
const swiftIDs = [...swiftProfiles.matchAll(/id:\s*"([^"]+)",\s*nameKo:/g)].map(match => match[1]);
assert.deepEqual(catalog.cats.map(cat => cat.id), swiftIDs);
const store = readFileSync(resolve(root, 'Sources/Meownitor/CatPackStore.swift'), 'utf8');
assert.ok(store.includes(`${downloadBase}/cat-packs.json`));
const referencedAssets = new Set(['icon.webp']);
for (const cat of catalog.cats) {
  for (const language of ['en', 'ko', 'ja']) assert.ok(cat.name[language] && cat.breed[language]);
  for (const filename of [`${cat.id}.webp`, `${cat.id}-idle.webp`]) {
    referencedAssets.add(filename);
    const image = readFileSync(resolve(web, 'assets', filename));
    assert.equal(image.toString('ascii', 0, 4), 'RIFF');
    assert.equal(image.toString('ascii', 8, 12), 'WEBP');
    assert.ok(image.length < 300_000, `${filename}: preview too large`);
  }
  if (cat.bundled) assert.equal(cat.url, undefined);
  else {
    assert.equal(cat.url, `${downloadBase}/Meownitor-Cat-${cat.id}-v1.zip`);
    assert.match(cat.sha256, /^[a-f0-9]{64}$/);
    assert.ok(cat.bytes > 0 && cat.bytes < 500_000_000);
  }
}
assert.deepEqual(readdirSync(resolve(web, 'assets')).sort(), [...referencedAssets].sort());
const totalBytes = [...referencedAssets].reduce((sum, name) => sum + statSync(resolve(web, 'assets', name)).size, 0);
assert.ok(totalBytes < 5_000_000, 'Keep the preview collection below 5 MB');
for (const [, path] of html.matchAll(/(?:href|src)="([^"#]+)"/g)) {
  if (!path.startsWith('https://')) assert.ok(statSync(resolve(web, path)).isFile(), path);
}
for (const [, anchor] of html.matchAll(/href="#([^"]+)"/g)) assert.ok(html.includes(`id="${anchor}"`), anchor);
for (const file of ['app.mjs', 'cats.mjs', 'content.mjs']) {
  const source = readFileSync(resolve(web, file), 'utf8');
  for (const [, path] of source.matchAll(/from '([^']+)'/g)) assert.ok(statSync(resolve(dirname(resolve(web, file)), path)).isFile());
}
console.log(`PASS: 3 languages, 21 cats, 17 release downloads, local links and ${(totalBytes / 1048576).toFixed(2)} MiB of previews.`);
