#!/usr/bin/env node
// Keeps cheatsheet/shortcuts.js in step with the configs.
//   node cheatsheet/check.mjs
// 1. The data itself is well formed (known tools, files exist, key syntax).
// 2. Every `src` matches exactly one non-comment line of its section's file
//    (catches keys changed or removed in a config, and a src so short that a
//    new binding could hide behind it).
// 3. Every key-binding line in the configs is covered by some item's `src`
//    (catches keys added to a config but not to the cheatsheet).
// 4. The tmux prefix in shortcuts.js matches .tmux.conf.
// Exits 1 if anything is out of step.

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');

const ctx = { window: {} };
vm.runInNewContext(readFileSync(join(here, 'shortcuts.js'), 'utf8'), ctx);
const { APPS, SECTIONS } = ctx.window;

// Per config: what counts as a binding line, which lines are comments, and
// which binding-looking lines to ignore (helpers).
const CONFIGS = {
  'ghostty/.config/ghostty/config.ghostty': { match: /^\s*keybind\s*=/, comment: /^\s*#/ },
  'tmux/.tmux.conf': { match: /^\s*bind(-key)?\s/, comment: /^\s*#/ },
  'zsh/.zshrc': { match: /^\s*(bindkey\s|alias\s|[\w-]+\(\)\s*\{)/, comment: /^\s*#/, ignore: /^\s*_\w+\(\)/ },
  'nvim/.config/nvim/init.lua': { match: /\bmap\(\s*[{'"]/, comment: /^\s*--/ },
  'vim/.vimrc': { match: /^\s*[nvxsoilct]?(nore)?map\s/, comment: /^\s*"/ },
};

const srcs = (item) => (item.src == null ? [] : [].concat(item.src));
const problems = [];
const lines = (f) => readFileSync(join(root, f), 'utf8').split('\n')
  .map((text, i) => ({ text, n: i + 1 }))
  .filter(({ text }) => !(CONFIGS[f]?.comment?.test(text)));

// 1. Data is well formed
const appIds = new Set(APPS.map((a) => a.id));
for (const s of SECTIONS) {
  for (const a of [].concat(s.app)) if (!appIds.has(a)) problems.push(`DATA   [${s.title}] unknown app "${a}" (known: ${[...appIds].join(', ')})`);
  if (s.file && !existsSync(join(root, s.file))) problems.push(`DATA   [${s.title}] file not found: ${s.file}`);
  for (const item of s.items) {
    if (!item.k || !item.d) problems.push(`DATA   [${s.title}] item needs k and d: ${JSON.stringify(item)}`);
    if (srcs(item).length && !s.file) problems.push(`DATA   [${s.title}] "${item.k}" has src but its section has no file`);
    for (const alt of String(item.k).split(' / ')) {
      if (!alt.trim() || /\s{2,}|^\s|\s$/.test(alt)) problems.push(`KEYS   [${s.title}] "${item.k}": empty alternative or stray spaces`);
      for (const press of alt.split(' ')) {
        if (press.length > 1 && /^\+|\+$|\+\+/.test(press)) problems.push(`KEYS   [${s.title}] "${item.k}": "${press}" — write a literal + as Plus`);
      }
    }
  }
}

// 2. Each src matches exactly one non-comment line
for (const s of SECTIONS) {
  if (!s.file || !existsSync(join(root, s.file))) continue;
  const text = lines(s.file);
  for (const item of s.items) {
    for (const src of srcs(item)) {
      let hits = text.filter((l) => l.text.includes(src));
      // Several lines contain it, but only one starts with it ("t() {" vs "_reset() {")
      const atStart = hits.filter((l) => l.text.trimStart().startsWith(src));
      if (hits.length > 1 && atStart.length === 1) hits = atStart;
      if (!hits.length) problems.push(`STALE  ${s.file}: "${item.k}" (${item.d}) — src not found: ${src}`);
      else if (hits.length > 1) problems.push(`VAGUE  ${s.file}: "${item.k}" src matches lines ${hits.map((h) => h.n).join(', ')}: ${src} — make it specific to one line`);
    }
  }
}

// 3. Every binding line covered
for (const [file, rule] of Object.entries(CONFIGS)) {
  if (!existsSync(join(root, file))) continue;
  const covered = SECTIONS.filter((s) => s.file === file).flatMap((s) => s.items.flatMap(srcs));
  for (const { text, n } of lines(file)) {
    if (!rule.match.test(text) || rule.ignore?.test(text)) continue;
    if (!covered.some((src) => text.includes(src))) problems.push(`MISSING ${file}:${n}: ${text.trim()}`);
  }
}

// 4. tmux prefix
const tmuxFile = 'tmux/.tmux.conf';
if (existsSync(join(root, tmuxFile))) {
  const set = lines(tmuxFile).map((l) => l.text.match(/^\s*set(-option)?\s+(-\w+\s+)*prefix\s+(\S+)/)).filter(Boolean).pop();
  const actual = set ? set[3].replace(/^C-/, 'Ctrl+').replace(/^M-/, 'Alt+') : 'Ctrl+b';
  const listed = APPS.find((a) => a.id === 'tmux')?.prefix || 'Ctrl+b';
  if (actual !== listed) problems.push(`PREFIX .tmux.conf sets the prefix to ${actual}, shortcuts.js says ${listed} — update APPS tmux.prefix`);
}

if (problems.length) {
  console.log(problems.join('\n'));
  console.log(`\n${problems.length} problem(s). Update cheatsheet/shortcuts.js.`);
  process.exit(1);
}
const n = SECTIONS.reduce((a, s) => a + s.items.length, 0);
console.log(`cheatsheet OK: ${n} shortcuts, all config bindings covered.`);
