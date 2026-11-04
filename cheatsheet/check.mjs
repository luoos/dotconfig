#!/usr/bin/env node
// Keeps cheatsheet/shortcuts.js in step with the configs.
//   node cheatsheet/check.mjs
// 1. Every item with `src` must still find that text in its section's file
//    (catches keys that were changed or removed in a config).
// 2. Every key-binding line in the configs must be covered by some item's
//    `src` (catches keys added to a config but not to the cheatsheet).
// Exits 1 if anything is out of step.

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');

const ctx = { window: {} };
vm.runInNewContext(readFileSync(join(here, 'shortcuts.js'), 'utf8'), ctx);
const { SECTIONS } = ctx.window;

// What counts as a "binding line" in each config. A line matching `skip` is
// ignored (comments, helpers that only look like bindings).
const BINDINGS = {
  'ghostty/.config/ghostty/config.ghostty': { match: /^\s*keybind\s*=/, skip: /^\s*#/ },
  'tmux/.tmux.conf': { match: /^\s*bind(-key)?\s/, skip: /^\s*#/ },
  'zsh/.zshrc': { match: /^\s*(bindkey\s|alias\s|[\w-]+\(\)\s*\{)/, skip: /^\s*#|^\s*_\w+\(\)/ },
  'nvim/.config/nvim/init.lua': { match: /\bmap\(\s*[{'"]/, skip: /^\s*--/ },
  'vim/.vimrc': { match: /^\s*[nvxsoilct]?(nore)?map\s/, skip: /^\s*"/ },
};

const srcs = (item) => (item.src == null ? [] : [].concat(item.src));
const problems = [];
const read = (f) => readFileSync(join(root, f), 'utf8');

// 1. src text still present
for (const s of SECTIONS) {
  for (const item of s.items) {
    if (!srcs(item).length) continue;
    if (!s.file) { problems.push(`[${s.title}] "${item.k}" has src but its section has no file`); continue; }
    if (!existsSync(join(root, s.file))) { problems.push(`[${s.title}] file not found: ${s.file}`); continue; }
    const text = read(s.file);
    for (const src of srcs(item)) {
      if (!text.includes(src)) problems.push(`STALE  ${s.file}: "${item.k}" (${item.d}) — src not found: ${src}`);
    }
  }
}

// 2. every binding line covered
for (const [file, rule] of Object.entries(BINDINGS)) {
  if (!existsSync(join(root, file))) continue;
  const covered = SECTIONS.filter((s) => s.file === file).flatMap((s) => s.items.flatMap(srcs));
  read(file).split('\n').forEach((line, i) => {
    if (!rule.match.test(line) || rule.skip.test(line)) return;
    if (!covered.some((src) => line.includes(src))) problems.push(`MISSING ${file}:${i + 1}: ${line.trim()}`);
  });
}

if (problems.length) {
  console.log(problems.join('\n'));
  console.log(`\n${problems.length} problem(s). Update cheatsheet/shortcuts.js.`);
  process.exit(1);
}
const n = SECTIONS.reduce((a, s) => a + s.items.length, 0);
console.log(`cheatsheet OK: ${n} shortcuts, all config bindings covered.`);
