import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const html = readFileSync(new URL('../web/copy-code.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];

function page(hash, { clipboardFails = false } = {}) {
  const elements = { code: { hidden: true, focus() {}, select() { this.selected = true; } }, copy: { disabled: true }, status: {} };
  let click;
  let clock = 1000;
  let tick;
  let copied;
  let replaced;
  elements.copy.addEventListener = (_, handler) => { click = handler; };
  runInNewContext(script, {
    URLSearchParams, Date: { now: () => clock },
    location: { hash, pathname: '/copy-code.html', search: '' },
    history: { replaceState: (_, __, url) => { replaced = url; } },
    document: { getElementById: (id) => elements[id] },
    navigator: { clipboard: { async writeText(code) {
      if (clipboardFails) throw Error('blocked');
      copied = code;
    } } },
    setInterval: (handler) => { tick = handler; },
  });
  return { elements, click: () => click(), copied: () => copied, replaced: () => replaced,
    advance: (time) => { clock = time; tick(); } };
}

test('copies six digits including leading zero and clears the URL fragment', async () => {
  const state = page('#code=012345&expires=2000');
  assert.equal(state.elements.copy.disabled, false);
  assert.equal(state.replaced(), '/copy-code.html');
  await state.click();
  assert.equal(state.copied(), '012345');
  assert.match(state.elements.status.textContent, /Code copied/);
});

test('invalid and expired links cannot copy a code', async () => {
  for (const hash of ['#code=012345&expires=999', '#code=<script>&expires=2000', '#code=012345']) {
    const state = page(hash);
    assert.equal(state.elements.copy.disabled, true);
    await state.click();
    assert.equal(state.copied(), undefined);
  }
});

test('a code expires while the page remains open', () => {
  const state = page('#code=012345&expires=2000');
  state.advance(2000);
  assert.equal(state.elements.copy.disabled, true);
  assert.equal(state.elements.code.value, '');
});

test('clipboard failure selects the code without falsely claiming it was copied', async () => {
  const state = page('#code=012345&expires=2000', { clipboardFails: true });
  await state.click();
  assert.equal(state.elements.code.selected, true);
  assert.match(state.elements.status.textContent, /choose Copy/);
  assert.equal(state.copied(), undefined);
});
