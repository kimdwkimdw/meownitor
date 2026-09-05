import { translations, ui, resolveLanguage, repository, releaseTag, downloadBase } from './content.mjs';
import { catalog } from './cats.mjs';

const textNodes = [...document.querySelectorAll('[data-i18n]')];
const ariaNodes = [...document.querySelectorAll('[data-i18n-aria]')];
const english = Object.fromEntries([
  ...textNodes.map(node => [node.dataset.i18n, node.textContent]),
  ...ariaNodes.map(node => [node.dataset.i18nAria, node.getAttribute('aria-label')]),
]);
let savedLanguage;
try { savedLanguage = localStorage.getItem('meownitor-language'); } catch { /* Storage is optional. */ }
let language = resolveLanguage(new URL(location.href).searchParams.get('lang'), savedLanguage, navigator.languages);
let selectedCat = catalog.cats[0];
let paused = false;
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
const motionToggle = document.querySelector('#motion-toggle');

function updatePreview() {
  const hero = document.querySelector('#hero-cat');
  hero.style.backgroundImage = `url("assets/${selectedCat.id}-idle.webp")`;
  hero.setAttribute('aria-label', `${selectedCat.name[language]} · ${selectedCat.breed[language]}`);
  document.querySelector('#hero-cat-name').textContent = selectedCat.name[language];
  document.querySelectorAll('.cat-card').forEach(card => {
    const selected = card.dataset.cat === selectedCat.id;
    card.classList.toggle('selected', selected);
    card.querySelector('button').setAttribute('aria-pressed', String(selected));
  });
}

function renderCats() {
  document.querySelector('#bundled-cats').replaceChildren();
  document.querySelector('#downloadable-cats').replaceChildren();
  for (const cat of catalog.cats) {
    const card = document.createElement('article');
    card.className = 'cat-card';
    card.dataset.cat = cat.id;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'cat-preview';
    button.setAttribute('aria-label', `${ui[language].preview}: ${cat.name[language]}`);
    const img = document.createElement('img');
    img.src = `assets/${cat.id}.webp`;
    img.alt = '';
    img.width = img.height = 320;
    img.loading = 'lazy';
    img.decoding = 'async';
    const name = document.createElement('span');
    name.className = 'cat-name';
    name.textContent = cat.name[language];
    const breed = document.createElement('span');
    breed.className = 'cat-breed';
    breed.textContent = cat.breed[language];
    button.append(img, name, breed);
    button.addEventListener('click', () => {
      selectedCat = cat;
      updatePreview();
      document.querySelector('.hero-stage').scrollIntoView({ behavior: reducedMotion.matches ? 'instant' : 'smooth', block: 'center' });
    });
    card.append(button);
    if (cat.bundled) {
      const badge = document.createElement('span');
      badge.className = 'included-badge';
      badge.textContent = `✓ ${ui[language].included}`;
      card.append(badge);
    } else {
      const link = document.createElement('a');
      link.className = 'cat-download';
      link.href = cat.url;
      link.setAttribute('aria-label', `${cat.name[language]} · ${ui[language].download}`);
      const label = document.createElement('span');
      label.textContent = `${ui[language].download} ↓`;
      const size = document.createElement('span');
      size.textContent = `${(cat.bytes / 1048576).toFixed(1)} MiB`;
      link.append(label, size);
      card.append(link);
    }
    document.querySelector(cat.bundled ? '#bundled-cats' : '#downloadable-cats').append(card);
  }
  updatePreview();
}

function updateMotion() {
  const stopped = paused || reducedMotion.matches;
  document.body.classList.toggle('paused', stopped);
  motionToggle.hidden = reducedMotion.matches;
  motionToggle.setAttribute('aria-pressed', String(stopped));
  motionToggle.textContent = ui[language][stopped ? 'play' : 'pause'];
}

function setLanguage(next) {
  language = next;
  document.documentElement.lang = next;
  document.title = ui[next].title;
  document.querySelector('meta[name="description"]').content = ui[next].description;
  document.querySelector('meta[property="og:title"]').content = ui[next].title;
  document.querySelector('meta[property="og:description"]').content = ui[next].description;
  const copy = next === 'en' ? english : translations[next];
  textNodes.forEach(node => { node.textContent = copy[node.dataset.i18n]; });
  ariaNodes.forEach(node => { node.setAttribute('aria-label', copy[node.dataset.i18nAria]); });
  document.querySelectorAll('[data-lang]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.lang === next)));
  renderCats();
  updateMotion();
}

document.querySelectorAll('[data-lang]').forEach(button => button.addEventListener('click', () => {
  setLanguage(button.dataset.lang);
  try { localStorage.setItem('meownitor-language', language); } catch { /* Storage is optional. */ }
  const url = new URL(location.href);
  url.searchParams.set('lang', language);
  history.replaceState(null, '', url);
}));
document.querySelectorAll('[data-release-asset]').forEach(link => { link.href = `${downloadBase}/${link.dataset.releaseAsset}`; });
document.querySelectorAll('[data-release-link]').forEach(link => { link.href = `${repository}/releases/tag/${releaseTag}`; });
motionToggle.addEventListener('click', () => { paused = !paused; updateMotion(); });
reducedMotion.addEventListener('change', updateMotion);
setLanguage(language);
