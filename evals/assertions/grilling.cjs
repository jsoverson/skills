// Assertions for evals/grilling.yaml. Each reads the session files the agent wrote under the
// grilling work dir and checks them with the skill's own nu scripts.
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const WORK = path.resolve(__dirname, '../.work/grilling');
const QDIR = path.join(WORK, 'docs/questioning');
const SCRIPTS = path.resolve(__dirname, '../../plugins/engineering/skills/grilling/scripts');
const FIXTURE = 'cache-layer.toml';
const FIXTURE_SOURCE = path.join(SCRIPTS, 'fixtures/answered.toml');

const nu = (script, ...args) =>
  execFileSync('nu', [path.join(SCRIPTS, script), ...args], { encoding: 'utf8', stdio: 'pipe' });

const nuJson = (expr, file) =>
  JSON.parse(execFileSync('nu', ['-c', `open '${file}' | ${expr} | to json`], { encoding: 'utf8' }));

// The session file named in the agent's reply, resolved against the work dir.
// Returns an error string when the reply names no file, or one outside the work dir.
const sessionFrom = (output) => {
  const named = String(output).match(/[\w./-]*docs\/questioning\/[\w.-]+\.toml/);
  if (!named) return { error: 'reply names no docs/questioning/*.toml file' };
  const file = path.resolve(WORK, named[0]);
  if (!file.startsWith(QDIR + path.sep)) return { error: `file is outside the work dir: ${file}` };
  if (!fs.existsSync(file)) return { error: `file does not exist: ${file}` };
  return { file };
};

const validate = (file) => {
  try {
    nu('validate.nu', file);
    return null;
  } catch (e) {
    return `${e.stdout}${e.stderr}`;
  }
};

// A new session file exists, validates, and holds round-1 questions.
function newSessionValid(output) {
  const { file, error } = sessionFrom(output);
  if (error) return { pass: false, score: 0, reason: error };
  const errors = validate(file);
  if (errors) return { pass: false, score: 0, reason: `validate.nu failed:\n${errors}` };
  const rounds = nuJson('transpose k v | where k =~ "^Q[0-9]+$" | get v.round | uniq', file);
  const pass = rounds.length === 1 && rounds[0] === 1;
  return { pass, score: pass ? 1 : 0, reason: pass ? `valid: ${path.basename(file)}` : `rounds: ${rounds}` };
}

// For manual review: passes when the file validates, and puts the whole file in the reason.
function showSession(output) {
  const { file, error } = sessionFrom(output);
  if (error) return { pass: false, score: 0, reason: error };
  const errors = validate(file);
  const text = fs.readFileSync(file, 'utf8');
  return { pass: !errors, score: errors ? 0 : 1, reason: `${errors ?? ''}\n${text}` };
}

// After "done" on the fixture: the user's answers are untouched, the file validates,
// and the reask question Q5 is re-asked with `replaces`.
function fixtureRound2() {
  const file = path.join(QDIR, FIXTURE);
  const errors = validate(file);
  if (errors) return { pass: false, score: 0, reason: `validate.nu failed:\n${errors}` };
  const original = nuJson('transpose k v | where k =~ "^Q[0-9]+$" | each {|r| {id: $r.k, choice: $r.v.choice, note: $r.v.note}}', FIXTURE_SOURCE);
  const now = nuJson('transpose k v | where k =~ "^Q[0-9]+$" | each {|r| {id: $r.k, round: $r.v.round, choice: ($r.v.choice? | default ""), note: ($r.v.note? | default ""), replaces: ($r.v.replaces? | default "")}}', file);
  const changed = original.filter((o) => {
    const n = now.find((q) => q.id === o.id);
    return !n || n.choice !== o.choice || n.note !== o.note;
  });
  if (changed.length) return { pass: false, score: 0, reason: `user answers changed: ${changed.map((c) => c.id)}` };
  const reasked = now.filter((q) => q.replaces === 'Q5' && q.round === 2);
  if (!reasked.length) return { pass: false, score: 0, reason: 'no round-2 question with replaces = "Q5"' };
  const fresh = now.filter((q) => q.round === 2 && (q.choice || q.note));
  if (fresh.length) return { pass: false, score: 0, reason: `round-2 questions pre-answered: ${fresh.map((q) => q.id)}` };
  return { pass: true, score: 1, reason: `round 2: ${now.filter((q) => q.round === 2).map((q) => q.id)}` };
}

module.exports = { newSessionValid, showSession, fixtureRound2 };
