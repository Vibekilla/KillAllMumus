#!/usr/bin/env node
/**
 * Convert beautified HTML canvas draw* JS → CanvasCompat GDScript.
 * Brace-stack walker so multi-line blocks stay intact. No placeholders.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import beautify from 'js-beautify';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const FUN = path.join(ROOT, 'tools/port/extracted/functions');
const OUT = path.join(ROOT, 'godot/scripts/render/drawers');
fs.mkdirSync(OUT, { recursive: true });

const CTX_PROPS = {
  fillStyle: 'fill_style', strokeStyle: 'stroke_style', lineWidth: 'line_width',
  globalAlpha: 'global_alpha', shadowColor: 'shadow_color', shadowBlur: 'shadow_blur',
  textAlign: 'text_align', textBaseline: 'text_baseline', lineJoin: 'line_join',
  lineCap: 'line_cap', font: 'font', globalCompositeOperation: 'global_composite_operation',
};
const CTX_METH = {
  beginPath: 'begin_path', closePath: 'close_path', moveTo: 'move_to', lineTo: 'line_to',
  quadraticCurveTo: 'quadratic_curve_to', bezierCurveTo: 'bezier_curve_to',
  arc: 'arc', ellipse: 'ellipse', fill: 'fill', stroke: 'stroke', save: 'save',
  restore: 'restore', translate: 'translate', rotate: 'rotate', scale: 'scale',
  fillRect: 'fill_rect', strokeRect: 'stroke_rect', clearRect: 'clear_rect',
  fillText: 'fill_text', strokeText: 'stroke_text', setLineDash: 'set_line_dash',
  clip: 'clip', rect: 'rect', roundRect: 'round_rect', drawImage: 'draw_image',
  measureText: 'measure_text', setTransform: 'set_transform',
};

function convertExpr(e) {
  let s = e.trim();
  s = s.replace(/Math\./g, '');
  s = s.replace(/===/g, '==').replace(/!==/g, '!=');
  s = s.replace(/\bundefined\b/g, 'null');
  s = s.replace(/\babs\(/g, 'absf(');
  s = s.replace(/\bmin\(/g, 'minf(');
  s = s.replace(/\bmax\(/g, 'maxf(');
  s = s.replace(/\bfloor\(/g, 'floorf(');
  s = s.replace(/\bceil\(/g, 'ceilf(');
  s = s.replace(/\bround\(/g, 'roundf(');
  s = s.replace(/\brandom\(\)/g, 'randf()');
  s = s.replace(/\bPI\b/g, 'PI');
  s = s.replace(/\bhypot\(([^,]+),([^)]+)\)/g, 'sqrt(($1)*($1)+($2)*($2))');
  s = s.replace(/(\w+)\.(\w+)\s*\|\|\s*([^|&\?:]+)/g, '$1.get("$2", $3)');
  s = s.replace(/\bselectedOutfit\b/g, 'selected_outfit');
  s = s.replace(/&&/g, ' and ');
  s = s.replace(/\|\|/g, ' or ');
  // ternary with ?
  for (let i = 0; i < 10; i++) {
    const n = s.replace(/([^?:\n]+?)\?\s*([^?:\n]+?)\s*:\s*([^?:\n,)]+)/g, '($2 if ($1) else $3)');
    if (n === s) break;
    s = n;
  }
  s = s.replace(/'([^'\\]*(?:\\.[^'\\]*)*)'/g, (_, i) => '"' + i.replace(/"/g, '\\"') + '"');
  return s;
}

function splitArgs(args) {
  if (!args || !String(args).trim()) return [];
  const parts = [];
  let d = 0, cur = '', inS = null;
  for (let i = 0; i < args.length; i++) {
    const c = args[i];
    if (inS) {
      cur += c;
      if (c === '\\') { cur += args[++i] || ''; continue; }
      if (c === inS) inS = null;
      continue;
    }
    if (c === '"' || c === "'") { inS = c; cur += c; continue; }
    if ('([{'.includes(c)) d++;
    else if (')]}'.includes(c)) d--;
    if (c === ',' && d === 0) { parts.push(cur.trim()); cur = ''; }
    else cur += c;
  }
  if (cur.trim()) parts.push(cur.trim());
  return parts;
}

function stripTrailingComment(t) {
  let inS = null, out = '';
  for (let i = 0; i < t.length; i++) {
    const c = t[i];
    if (inS) {
      out += c;
      if (c === '\\') { out += t[++i] || ''; continue; }
      if (c === inS) inS = null;
      continue;
    }
    if (c === '"' || c === "'") { inS = c; out += c; continue; }
    if (c === '/' && t[i + 1] === '/') break;
    out += c;
  }
  return out.trim();
}

function convertStmt(t, ind, locals) {
  t = stripTrailingComment(t);
  while (t.endsWith(';')) t = t.slice(0, -1).trim();
  if (!t) return [];
  const pad = '\t'.repeat(ind);

  // if / else if / else — only condition, body handled by walker
  let m = t.match(/^else\s+if\s*\((.*)\)$/);
  if (m) return [pad + 'elif ' + convertExpr(m[1]) + ':'];
  m = t.match(/^if\s*\((.*)\)$/);
  if (m) return [pad + 'if ' + convertExpr(m[1]) + ':'];
  if (t === 'else') return [pad + 'else:'];

  m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<\s*([^;]+);\s*\1\+\+\s*\)$/);
  if (m) return [pad + `for ${m[1]} in range(int(${convertExpr(m[2])}), int(${convertExpr(m[3])})):`];
  m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<=\s*([^;]+);\s*\1\+\+\s*\)$/);
  if (m) return [pad + `for ${m[1]} in range(int(${convertExpr(m[2])}), int(${convertExpr(m[3])}) + 1):`];
  m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s+of\s+(.+)\)$/);
  if (m) return [pad + `for ${m[1]} in ${convertExpr(m[2])}:`];

  // for (let i = a; i < b; i += n)
  m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<\s*([^;]+);\s*\1\s*\+=\s*([^)]+)\)$/);
  if (m) return [pad + `for ${m[1]} in range(int(${convertExpr(m[2])}), int(${convertExpr(m[3])}), int(${convertExpr(m[4])})):`];

  m = t.match(/^(?:const|let|var)\s+(.+)$/);
  if (m && !m[1].includes('=>')) {
    const parts = splitArgs(m[1]);
    const o = [];
    for (const p of parts) {
      const eq = p.indexOf('=');
      if (eq < 0) continue;
      let nm = p.slice(0, eq).trim();
      const val = convertExpr(p.slice(eq + 1));
      if (nm === 'armSw') { o.push(pad + `_armSw = ${val}`); continue; }
      if (nm === 'sBob') { o.push(pad + `_sBob = ${val}`); continue; }
      if (nm === 'hold') { o.push(pad + `_hold = ${val}`); continue; }
      o.push(pad + `var ${nm} = ${val}`);
    }
    return o.length ? o : [pad + '# TODO_PORT: ' + t.slice(0, 100)];
  }

  if (t.startsWith('return')) {
    const v = t.slice(6).trim();
    return [pad + (v ? 'return ' + convertExpr(v) : 'return')];
  }
  if (t === 'continue' || t === 'break') return [pad + t];

  m = t.match(/^ctx\.(\w+)\s*=\s*(.+)$/);
  if (m) return [pad + `ctx.${CTX_PROPS[m[1]] || m[1]}(${convertExpr(m[2])})`];

  m = t.match(/^ctx\.(\w+)\s*\((.*)\)$/);
  if (m) {
    const meth = CTX_METH[m[1]] || CTX_PROPS[m[1]] || m[1];
    return [pad + `ctx.${meth}(${splitArgs(m[2]).map(convertExpr).join(', ')})`];
  }

  m = t.match(/^([A-Za-z_][\w\.]*)\s*=\s*(.+)$/);
  if (m) {
    let lhs = m[1];
    if (lhs === 'hold') lhs = '_hold';
    if (lhs === 'armSw') lhs = '_armSw';
    if (lhs === 'sBob') lhs = '_sBob';
    return [pad + `${lhs} = ${convertExpr(m[2])}`];
  }

  m = t.match(/^([A-Za-z_][\w\.]*)\s*\((.*)\)$/);
  if (m) {
    let fn = m[1];
    if (locals[fn]) fn = '_' + fn;
    if (fn === 'pOrb') fn = 'p_orb';
    if (fn === 'circle') fn = 'draw_circle_helper';
    if (fn === 'limb') fn = 'draw_limb';
    return [pad + `${fn}(${splitArgs(m[2]).map(convertExpr).join(', ')})`];
  }

  // createLinearGradient not supported — mark real gap
  if (t.includes('createLinearGradient') || t.includes('addColorStop')) {
    return [pad + '# TODO_PORT gradient: ' + t.slice(0, 100)];
  }

  return [pad + '# TODO_PORT: ' + t.slice(0, 140)];
}

/** Walk body text with brace stack → indented GD lines */
function walkBody(body, baseInd, locals) {
  const lines = body.split('\n');
  const out = [];
  let i = 0;
  // join lines that continue with trailing comma
  const joined = [];
  for (let k = 0; k < lines.length; k++) {
    let L = lines[k];
    const sc = stripTrailingComment(L);
    while (/,\s*$/.test(sc) && k + 1 < lines.length) {
      k++;
      L = stripTrailingComment(L).replace(/,\s*$/, ',') + ' ' + lines[k].trim();
    }
    joined.push(L);
  }

  // process with indent from braces
  let ind = baseInd;
  for (const line of joined) {
    let t = line.trim();
    if (!t) continue;
    if (t.startsWith('//')) {
      out.push('\t'.repeat(ind) + '#' + t.slice(2));
      continue;
    }
    // count leading close braces
    while (t.startsWith('}')) {
      ind = Math.max(baseInd, ind - 1);
      t = t.slice(1).trim();
      if (t.startsWith('else')) break;
      if (!t) break;
    }
    if (!t) continue;

    const opens = (t.match(/\{/g) || []).length;
    const closes = (t.match(/\}/g) || []).length;
    // strip trailing { for control statements
    let stmt = t.replace(/\s*\{\s*$/, '').replace(/;\s*$/, '');
    // remove trailing } on same line rare
    stmt = stmt.replace(/\s*\}\s*$/, '');

    if (stmt) {
      const converted = convertStmt(stmt, ind, locals);
      out.push(...converted);
    }
    // adjust indent for next lines
    if (opens > closes) ind += opens - closes;
    else if (closes > opens) ind = Math.max(baseInd, ind - (closes - opens));
  }
  return out;
}

function convertFile(name) {
  const js = fs.readFileSync(path.join(FUN, name + '.js'), 'utf8');
  let pretty = beautify.js(js, { indent_size: 2, brace_style: 'expand', end_with_newline: true });
  // expand single-line if (cond) stmt;
  pretty = pretty.replace(
    /^(\s*)if\s*\((.+)\)\s+([^;\n{]+);?\s*$/gm,
    (_, sp, cond, stmt) => `${sp}if (${cond}) {\n${sp}  ${stmt};\n${sp}}`
  );
  fs.writeFileSync(path.join(FUN, name + '.pretty.js'), pretty);

  const m = pretty.match(/^function\s+\w+\s*\(([^)]*)\)\s*\{([\s\S]*)\}\s*$/m);
  if (!m) throw new Error('parse ' + name);
  const params = m[1].split(',').map(p => p.trim()).filter(Boolean).map(p => p.split('=')[0].trim());
  let body = m[2];

  // extract nested arrows to methods
  const locals = {};
  const arrowRe = /(?:const|let|var)\s+(\w+)\s*=\s*\(([^)]*)\)\s*=>\s*\{/g;
  let match; const reps = [];
  while ((match = arrowRe.exec(body))) {
    const fname = match[1], fargs = match[2];
    let start = match.index + match[0].length - 1, depth = 0, i = start;
    for (; i < body.length; i++) {
      if (body[i] === '{') depth++;
      else if (body[i] === '}') { depth--; if (depth === 0) break; }
    }
    locals[fname] = { args: fargs, body: body.slice(start + 1, i) };
    reps.push({ start: match.index, end: i + 1 });
  }
  for (const r of reps.sort((a, b) => b.start - a.start)) {
    body = body.slice(0, r.start) + body.slice(r.end);
  }
  body = body.replace(/(?:const|let|var)\s+(\w+)\s*=\s*\(([^)]*)\)\s*=>\s*\{\s*\};?/g, (_, fn, a) => {
    locals[fn] = { args: a, body: '' };
    return '';
  });

  let localGd = '';
  for (const [fname, { args, body: fb }] of Object.entries(locals)) {
    const fargs = args.split(',').map(a => a.trim()).filter(Boolean).join(', ');
    let lines = walkBody(fb, 1, locals).map(l =>
      l.replace(/\bhold\b/g, '_hold')
        .replace(/\barmSw\b/g, '_armSw')
        .replace(/\bsBob\b/g, '_sBob')
        .replace(/\bpOrb\(/g, 'p_orb(')
    );
    localGd += `\nfunc _${fname}(${fargs}) -> void:\n` + (lines.length ? lines.join('\n') + '\n' : '\tpass\n');
  }

  let main = walkBody(body, 1, locals).map(l => {
    let x = l;
    for (const fname of Object.keys(locals)) {
      x = x.replace(new RegExp(`\\b${fname}\\(`, 'g'), `_${fname}(`);
    }
    x = x.replace(/\bpOrb\(/g, 'p_orb(');
    x = x.replace(/\bcircle\(/g, 'draw_circle_helper(');
    x = x.replace(/\bselectedOutfit\b/g, 'selected_outfit');
    x = x.replace(/=\s*ctx\.globalAlpha\b/g, '= ctx.get_alpha()');
    x = x.replace(/=\s*ctx\.global_alpha\b(?!\()/g, '= ctx.get_alpha()');
    x = x.replace(/\barmSw\b/g, '_armSw');
    x = x.replace(/\bsBob\b/g, '_sBob');
    x = x.replace(/\bhold\b/g, '_hold');
    return x;
  });

  return `extends RefCounted
## 1:1 port of HTML ${name}

var ctx
var tick: int = 0
var selected_outfit: String = "og"
var EAR_HIDE := {
	"neko": true, "monke": true, "kigurumi": true, "cheese": true, "cabal": true,
	"badger": true, "viking": true, "samurai": true, "bullbina": true, "jester": true,
	"succubus": true, "squirrely": true, "banana": true
}
var _armCol = "#5f3823"
var _armW: float = 3.8
var _handCols = null
var _hold = null
var _armSw: float = 0.0
var _sBob: float = 0.0

func setup(c) -> void:
	ctx = c

func set_tick(t: int) -> void:
	tick = t

func set_outfit(o: String) -> void:
	selected_outfit = o

func p_orb(x, y, glow, c1, c2) -> void:
	ctx.save()
	ctx.translate(float(x), float(y))
	ctx.global_alpha(0.55)
	ctx.fill_style(str(glow))
	ctx.begin_path()
	ctx.arc(0, 0, 5.5, 0, TAU)
	ctx.fill()
	ctx.global_alpha(1.0)
	ctx.fill_style(str(c1))
	ctx.begin_path()
	ctx.arc(0, 0, 3.2, 0, TAU)
	ctx.fill()
	ctx.fill_style(str(c2))
	ctx.begin_path()
	ctx.arc(-0.8, -0.8, 1.2, 0, TAU)
	ctx.fill()
	ctx.restore()

func draw_circle_helper(x, y, r, col) -> void:
	ctx.fill_style(col)
	ctx.begin_path()
	ctx.arc(float(x), float(y), float(r), 0, TAU)
	ctx.fill()
${localGd}
func ${name}(${params.join(', ')}) -> void:
${main.length ? main.join('\n') : '\tpass'}
`;
}

const names = process.argv.slice(2);
const list = names.length ? names : [
  'drawBobina', 'drawMumu', 'drawElite', 'drawPShot', 'drawBullet',
  'drawApe', 'drawMumina', 'drawLily', 'drawBoss', 'drawBogdanoff',
  'drawWynn', 'drawPolice', 'drawDevil', 'drawHoneyBadger', 'drawRobotnik',
  'drawTitle', 'drawStageBg', 'drawFx', 'drawMeleeFx', 'drawItem',
];

for (const n of list) {
  try {
    const gd = convertFile(n);
    fs.writeFileSync(path.join(OUT, n + '.gd'), gd);
    const todos = (gd.match(/TODO_PORT/g) || []).length;
    console.log('OK', n, 'lines', gd.split('\n').length, 'todos', todos);
  } catch (e) {
    console.error('FAIL', n, e.message);
  }
}
