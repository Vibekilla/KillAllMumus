#!/usr/bin/env node
/**
 * Convert extracted HTML game JS functions into GDScript methods
 * targeting CanvasCompat (ctx) + HtmlGame state (self./globals).
 *
 * This is a mechanical translator for 1:1 porting — output is reviewed
 * and loaded into HtmlGame modules.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const FUN = path.join(ROOT, 'tools/port/extracted/functions');
const OUT = path.join(ROOT, 'godot/scripts/html_parity/ported');
fs.mkdirSync(OUT, { recursive: true });

function convertBody(js) {
  let s = js;
  // strip function wrapper keep body
  s = s.replace(/^function\s+([A-Za-z_$][\w$]*)\s*\(([^)]*)\)\s*\{/, '');
  // remove trailing outer close if balanced poorly — keep as-is and fix braces later
  if (s.trimEnd().endsWith('}')) {
    // only strip last brace of function
    const idx = s.lastIndexOf('}');
    s = s.slice(0, idx);
  }

  // comments
  // Math
  s = s.replace(/Math\./g, '');
  s = s.replace(/Number\(/g, 'float(');
  s = s.replace(/parseInt\(/g, 'int(');
  s = s.replace(/parseFloat\(/g, 'float(');
  s = s.replace(/isNaN\(/g, 'is_nan(');
  s = s.replace(/\.length\b/g, '.size()' ); // arrays — careful with strings
  // fix string .size() back for common string patterns later

  // equality
  s = s.replace(/===/g, '==');
  s = s.replace(/!==/g, '!=');

  // boolean
  s = s.replace(/\btrue\b/g, 'true');
  s = s.replace(/\bfalse\b/g, 'false');
  s = s.replace(/\bnull\b/g, 'null');
  s = s.replace(/\bundefined\b/g, 'null');

  // console
  s = s.replace(/console\.(log|warn|error)/g, 'print');

  // ctx canvas API → ctx.
  // already ctx.xxx in source

  // object literals {a:1} stay — GDScript supports
  // for (const x of arr) → for x in arr
  s = s.replace(/for\s*\(\s*(?:const|let|var)\s+(\w+)\s+of\s+/g, 'for $1 in ');
  s = s.replace(/for\s*\(\s*(?:const|let|var)\s+(\w+)\s+in\s+/g, 'for $1 in ');
  // C-style for
  s = s.replace(
    /for\s*\(\s*(?:let|var|const)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*([<>]=?)\s*([^;]+);\s*\1(\+\+|--|\+=\s*[^)]+)\s*\)/g,
    (match, v, init, op, lim, inc) => {
      // for i in range
      if (op.startsWith('<') && (inc === '++' || inc.trim() === '++')) {
        return `for ${v} in range(int(${init}), int(${lim}))`;
      }
      return match; // leave hard ones
    }
  );
  s = s.replace(/\+\+/g, ' += 1');
  s = s.replace(/--/g, ' -= 1');

  // const/let/var → var
  s = s.replace(/\bconst\b/g, 'var');
  s = s.replace(/\blet\b/g, 'var');
  s = s.replace(/\bvar var\b/g, 'var');

  // arrow functions (simple)
  s = s.replace(
    /\(([^)]*)\)\s*=>\s*\{/g,
    'func($1): # arrow\n'
  );
  s = s.replace(
    /(\w+)\s*=>\s*/g,
    'func($1): return '
  );

  // new Set() → {}
  s = s.replace(/new Set\(\)/g, '{}');
  s = s.replace(/\.has\(/g, '.has(');
  s = s.replace(/\.add\(/g, '['); // weak — mark TODO

  // Object.assign
  s = s.replace(/Object\.assign\(([^,]+),\s*/g, '$1.merge(');

  // template strings
  s = s.replace(/`([^`]*)`/g, (m, inner) => {
    if (!inner.includes('${')) return '"' + inner.replace(/"/g, '\\"') + '"';
    // convert ${} to %
    let out = '"';
    let rest = inner;
    // simple approach: use str concat
    out = '"' + inner.replace(/\$\{([^}]+)\}/g, '" + str($1) + "') + '"';
    return out.replace(/"" \+ /g, '').replace(/ \+ ""/g, '');
  });

  // Array methods
  s = s.replace(/\.push\(/g, '.append(');
  s = s.replace(/\.pop\(\)/g, '.pop_back()');
  s = s.replace(/\.shift\(\)/g, '.pop_front()');
  s = s.replace(/\.filter\(/g, '.filter('); // needs lambda rewrite
  s = s.replace(/\.map\(/g, '.map(');
  s = s.replace(/\.forEach\(/g, ' # forEach ');
  s = s.replace(/\.includes\(/g, '.has(');
  s = s.replace(/\.indexOf\(/g, '.find(');

  // this → self
  s = s.replace(/\bthis\./g, 'self.');

  // window/document stubs
  s = s.replace(/localStorage\.getItem/g, 'HtmlBridge.storage_get');
  s = s.replace(/localStorage\.setItem/g, 'HtmlBridge.storage_set');
  s = s.replace(/document\./g, 'HtmlBridge.doc.');
  s = s.replace(/window\./g, 'HtmlBridge.win.');
  s = s.replace(/addEventListener\(/g, 'HtmlBridge.add_listener(');

  // ternary stays ok in GDScript
  // switch → match not auto

  // hypot
  s = s.replace(/\bhypot\(/g, 'sqrt_sum_sq(');

  // random
  s = s.replace(/\brandom\(\)/g, 'randf()');

  // PI
  s = s.replace(/\bPI\b/g, 'PI');
  s = s.replace(/\babs\(/g, 'absf(');
  s = s.replace(/\bmin\(/g, 'minf(');
  s = s.replace(/\bmax\(/g, 'maxf(');
  s = s.replace(/\bfloor\(/g, 'floorf(');
  s = s.replace(/\bceil\(/g, 'ceilf(');
  s = s.replace(/\bround\(/g, 'roundf(');
  s = s.replace(/\bsin\(/g, 'sin(');
  s = s.replace(/\bcos\(/g, 'cos(');
  s = s.replace(/\batan2\(/g, 'atan2(');

  // remove 'use strict' etc
  s = s.replace(/["']use strict["'];?/g, '');

  return s;
}

function convertFunction(name, js) {
  const sig = js.match(/^function\s+\w+\s*\(([^)]*)\)/);
  const params = sig ? sig[1] : '';
  // map params to GDScript untyped
  const gdParams = params
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean)
    .map((p) => p.split('=')[0].trim())
    .map((p) => p.replace(/\.\.\./, ''))
    .filter(Boolean)
    .join(', ');

  let body = convertBody(js);
  // indent body
  body = body
    .split('\n')
    .map((l) => (l.trim() ? '\t' + l : l))
    .join('\n');

  return `## AUTO-PORTED from HTML function ${name} — review required
func ${name}(${gdParams}):
${body}
`;
}

const files = fs.readdirSync(FUN).filter((f) => f.endsWith('.js'));
const meta = { converted: 0, failed: [] };
const all = [];

for (const f of files) {
  const name = f.replace(/\.js$/, '');
  const js = fs.readFileSync(path.join(FUN, f), 'utf8');
  try {
    const gd = convertFunction(name, js);
    fs.writeFileSync(path.join(OUT, name + '.gd.txt'), gd);
    all.push({ name, path: 'ported/' + name + '.gd.txt', lines: gd.split('\n').length });
    meta.converted++;
  } catch (e) {
    meta.failed.push({ name, error: e.message });
  }
}

// Master index
fs.writeFileSync(path.join(OUT, '_index.json'), JSON.stringify(all, null, 2));
fs.writeFileSync(path.join(OUT, '_meta.json'), JSON.stringify(meta, null, 2));
console.log(JSON.stringify(meta, null, 2));
