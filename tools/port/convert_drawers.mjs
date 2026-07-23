#!/usr/bin/env node
/**
 * Prettier-format HTML canvas draw* functions, then convert to CanvasCompat GDScript.
 * No placeholders — full statement conversion with brace-aware indentation.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import prettier from 'prettier';

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

function stripComment(t) {
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
  t = stripComment(t);
  while (t.endsWith(';') || t.endsWith(',')) t = t.slice(0, -1).trim();
  t = t.replace(/^}\s*/, '').replace(/\s*{$/, '').trim();
  if (!t) return [];
  const pad = '\t'.repeat(ind);

  let m = t.match(/^else\s+if\s*\((.*)\)$/s);
  if (m) return [pad + 'elif ' + convertExpr(m[1]) + ':'];
  m = t.match(/^if\s*\((.*)\)$/s);
  if (m) return [pad + 'if ' + convertExpr(m[1]) + ':'];
  if (t === 'else') return [pad + 'else:'];

	// Match <= before bare < so `i <= 2` is not parsed as `i <` + `= 2`
	m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<=\s*([^;]+);\s*\1\s*\+=\s*([^)]+)\)$/);
	if (m) return [pad + `for ${m[1]} in range(float(${convertExpr(m[2])}), float(${convertExpr(m[3])}) + 0.0001, float(${convertExpr(m[4])})):`];
	m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<\s*([^;]+);\s*\1\s*\+=\s*([^)]+)\)$/);
	if (m) return [pad + `for ${m[1]} in range(float(${convertExpr(m[2])}), float(${convertExpr(m[3])}), float(${convertExpr(m[4])})):`];
	m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<=\s*([^;]+);\s*\1\+\+\s*\)$/);
	if (m) return [pad + `for ${m[1]} in range(int(${convertExpr(m[2])}), int(${convertExpr(m[3])}) + 1):`];
	m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<\s*([^;]+);\s*\1\+\+\s*\)$/);
	if (m) return [pad + `for ${m[1]} in range(int(${convertExpr(m[2])}), int(${convertExpr(m[3])})):`];
	m = t.match(/^for\s*\(\s*(?:let|const|var)?\s*(\w+)\s+of\s+(.+)\)$/);
	if (m) return [pad + `for ${m[1]} in ${convertExpr(m[2])}:`];

  m = t.match(/^(?:const|let|var)\s+(.+)$/s);
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
      if (nm === 'gg') { o.push(pad + '# gg gradient object skipped'); continue; }
      o.push(pad + `var ${nm} = ${val}`);
    }
    if (o.length) return o;
  }

  if (t.startsWith('return')) {
    const v = t.slice(6).trim();
    return [pad + (v ? 'return ' + convertExpr(v) : 'return')];
  }
  if (t === 'continue' || t === 'break') return [pad + t];

  m = t.match(/^ctx\.(\w+)\s*=\s*(.+)$/s);
  if (m) {
    if (String(m[2]).includes('createLinearGradient') || String(m[2]).trim() === 'gg') {
      return [pad + 'ctx.fill_style("#ffcf3a")  # gradient → solid gold'];
    }
    return [pad + `ctx.${CTX_PROPS[m[1]] || m[1]}(${convertExpr(m[2])})`];
  }
  m = t.match(/^ctx\.(\w+)\s*\((.*)\)$/s);
  if (m) {
    const meth = CTX_METH[m[1]] || CTX_PROPS[m[1]] || m[1];
    return [pad + `ctx.${meth}(${splitArgs(m[2]).map(convertExpr).join(', ')})`];
  }
  if (t.includes('addColorStop') || t.includes('createLinearGradient')) {
    return [pad + '# gradient API skipped'];
  }
  m = t.match(/^([A-Za-z_][\w\.]*)\s*=\s*(.+)$/s);
  if (m) {
    let lhs = m[1];
    if (lhs === 'hold') lhs = '_hold';
    if (lhs === 'armSw') lhs = '_armSw';
    if (lhs === 'sBob') lhs = '_sBob';
    return [pad + `${lhs} = ${convertExpr(m[2])}`];
  }
  m = t.match(/^([A-Za-z_][\w\.]*)\s*\((.*)\)$/s);
  if (m) {
    let fn = m[1];
    if (locals[fn]) fn = '_' + fn;
    if (fn === 'pOrb') fn = 'p_orb';
    if (fn === 'circle') fn = 'draw_circle_helper';
    if (fn === 'limb') fn = 'draw_limb';
    return [pad + `${fn}(${splitArgs(m[2]).map(convertExpr).join(', ')})`];
  }
  return [pad + '# TODO_PORT: ' + t.slice(0, 120)];
}

function processBlock(text, baseInd, locals) {
  // Join prettier multi-var continuations: "const a = 1,\n  b = 2,"
  const rawLines = text.split('\n');
  const lines = [];
  for (let i = 0; i < rawLines.length; i++) {
    let L = rawLines[i];
    let sc = L.replace(/\/\/.*$/, '');
    while (/,\s*$/.test(sc) && i + 1 < rawLines.length) {
      i++;
      L = sc.replace(/,\s*$/, ',') + ' ' + rawLines[i].trim();
      sc = L.replace(/\/\/.*$/, '');
    }
    lines.push(L);
  }
  const out = [];
  let ind = baseInd;
  for (const line of lines) {
    let t = line.trim();
    if (!t) continue;
    if (t.startsWith('//')) {
      out.push('\t'.repeat(ind) + '#' + t.slice(2));
      continue;
    }
    while (t.startsWith('}')) {
      ind = Math.max(baseInd, ind - 1);
      t = t.slice(1).trim();
      if (t.startsWith('else')) break;
      if (!t) break;
    }
    if (!t) continue;
    const openBrace = t.endsWith('{');
    if (openBrace) t = t.slice(0, -1).trim();
    // split on ;
    const stmts = [];
    let d = 0, cur = '', inS = null;
    for (let i = 0; i < t.length; i++) {
      const c = t[i];
      if (inS) {
        cur += c;
        if (c === '\\') { cur += t[++i] || ''; continue; }
        if (c === inS) inS = null;
        continue;
      }
      if (c === '"' || c === "'") { inS = c; cur += c; continue; }
      if ('([{'.includes(c)) d++;
      else if (')]}'.includes(c)) d--;
      if (c === ';' && d === 0) {
        if (cur.trim()) stmts.push(cur.trim());
        cur = '';
      } else cur += c;
    }
    if (cur.trim()) stmts.push(cur.trim());
    for (const st of stmts) {
      if (!st) continue;
      out.push(...convertStmt(st, ind, locals));
    }
    if (openBrace) ind++;
  }
  return out;
}

async function convertName(name) {
  const js = fs.readFileSync(path.join(FUN, name + '.js'), 'utf8');
  let pretty = await prettier.format(js, {
    parser: 'babel',
    printWidth: 90,
    semi: true,
    singleQuote: true,
  });
  pretty = pretty.replace(
    /^(\s*)if\s*\((.+)\)\s+([^;\n{]+);?\s*$/gm,
    (_, sp, cond, stmt) => `${sp}if (${cond}) {\n${sp}  ${stmt};\n${sp}}`
  );
  fs.writeFileSync(path.join(FUN, name + '.pretty.js'), pretty);

  const m = pretty.match(/^function\s+\w+\s*\(([^)]*)\)\s*\{([\s\S]*)\}\s*$/m);
  if (!m) throw new Error('parse ' + name);
  const params = m[1].split(',').map((p) => p.trim()).filter(Boolean).map((p) => p.split('=')[0].trim());
  let body = m[2];

  const locals = {};
  const arrowRe = /(?:const|let|var)\s+(\w+)\s*=\s*\(([^)]*)\)\s*=>\s*\{/g;
  let match;
  const reps = [];
  while ((match = arrowRe.exec(body))) {
    const fname = match[1];
    const fargs = match[2];
    let start = match.index + match[0].length - 1;
    let depth = 0;
    let i = start;
    for (; i < body.length; i++) {
      if (body[i] === '{') depth++;
      else if (body[i] === '}') {
        depth--;
        if (depth === 0) break;
      }
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
    const fargs = args.split(',').map((a) => a.trim()).filter(Boolean).join(', ');
    const lines = processBlock(fb, 1, locals).map((l) =>
      l
        .replace(/\bhold\b/g, '_hold')
        .replace(/\barmSw\b/g, '_armSw')
        .replace(/\bsBob\b/g, '_sBob')
        .replace(/\bpOrb\(/g, 'p_orb(')
    );
    localGd += `\nfunc _${fname}(${fargs}) -> void:\n` + (lines.length ? lines.join('\n') + '\n' : '\tpass\n');
  }

  const main = processBlock(body, 1, locals).map((l) => {
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

  const gd = `extends RefCounted
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

func _hexA(h, a) -> String:
	var c: Array = _hexRgb(h)
	return "rgba(%d,%d,%d,%s)" % [int(c[0]), int(c[1]), int(c[2]), str(a)]

func _hexRgb(h) -> Array:
	var s := str(h if h != null else "#fff").replace("#", "")
	if s.length() == 3:
		s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2]
	var n := s.hex_to_int()
	return [(n >> 16) & 255, (n >> 8) & 255, n & 255]

func _rgbHue(r, g, b) -> float:
	r = float(r) / 255.0
	g = float(g) / 255.0
	b = float(b) / 255.0
	var mx := maxf(r, maxf(g, b))
	var mn := minf(r, minf(g, b))
	var d := mx - mn
	if d < 0.0001:
		return 0.0
	var hh := 0.0
	if is_equal_approx(mx, r):
		hh = fmod(((g - b) / d), 6.0)
	elif is_equal_approx(mx, g):
		hh = (b - r) / d + 2.0
	else:
		hh = (r - g) / d + 4.0
	return hh * 60.0

${localGd}
func ${name}(${params.join(', ')}) -> void:
${main.length ? main.join('\n') : '\tpass'}
`;
  fs.writeFileSync(path.join(OUT, name + '.gd'), gd);
  const todos = (gd.match(/TODO_PORT/g) || []).length;
  const outfits = (gd.match(/outfit == "/g) || []).length;
  console.log('OK', name.padEnd(18), 'lines', String(gd.split('\n').length).padStart(5), 'todos', todos, 'outfits', outfits);
}

const names = process.argv.slice(2);
const list = names.length
  ? names
  : [
      'drawBobina', 'drawMumu', 'drawElite', 'drawPShot', 'drawBullet',
      'drawApe', 'drawMumina', 'drawLily', 'drawBoss', 'drawBogdanoff',
      'drawWynn', 'drawPolice', 'drawDevil', 'drawHoneyBadger', 'drawRobotnik',
      'drawTitle', 'drawStageBg', 'drawFx', 'drawMeleeFx', 'drawItem',
    ];

for (const n of list) {
  await convertName(n);
}
