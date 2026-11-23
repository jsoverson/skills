# Tests for the grilling scripts. Run: nu test.nu
use std/assert
use grill.nu
use review.nu

const FIXTURE = path self fixtures/answered.toml

def fixture [] { open $FIXTURE }

def scratch [] {
  let f = (mktemp --suffix .toml)
  cp $FIXTURE $f
  $f
}

def with-question [id: string, fields: record] {
  fixture | merge deep {$id: $fields}
}

def "test status" [] {
  let qs = (fixture | grill questions | select id status)
  assert equal $qs [
    {id: Q1, status: accepted}
    {id: Q2, status: accepted}
    {id: Q3, status: answered}
    {id: Q4, status: superseded}
    {id: Q5, status: reask}
    {id: Q6, status: open}
    {id: Q7, status: dropped}
  ]
}

def "test an answer overrides dropped" [] {
  let q = (with-question Q7 {choice: a} | grill questions | where id == Q7 | first)
  assert equal $q.status accepted
}

def "test fixture is valid" [] {
  assert equal (fixture | grill validate) []
}

def "test validate catches bad fields" [] {
  let doc = (with-question Q1 {choice: z, recommended: c, recs: {ab: "x"}} | merge deep {Q2: {replaces: Q1}, Q3: {replaces: Q99}})
  let errors = ($doc | grill validate)
  assert ("Q1: choice 'z' must be empty, a rec letter, superseded, or reask" in $errors)
  assert ("Q1: recommended 'c' is not a rec" in $errors)
  assert ("Q1: rec 'ab' must be a single letter a-h" in $errors)
  assert ("Q2: replaces 'Q1', which is not marked reask" in $errors)
  assert ("Q3: replaces 'Q99' does not exist" in $errors)
}

def "test validate catches gaps and missing fields" [] {
  let doc = (fixture | reject Q3 | merge {Q9: {round: 2, title: "", body: "b", recs: {}}, stray: 1} | reject goal)
  let errors = ($doc | grill validate)
  assert ("Q4: ids must run Q1, Q2, ... without gaps; expected Q3" in $errors)
  assert ("Q9: round 2 has no [round.2] table" in $errors)
  assert ("Q9: title is missing" in $errors)
  assert ("Q9: needs at least one rec" in $errors)
  assert ("Q9: recommended is missing" in $errors)
  assert ("stray: unknown top-level key; questions are named Q<n>" in $errors)
  assert ("goal: missing" in $errors)
}

def "test digest" [] {
  assert equal (fixture | grill digest) ([
    "Q1 Use Redis as the cache store?: [a] Redis"
    "Q2 Invalidate on write?: [a] Delete the key on write  -- but only for user records"
    "Q3 TTL for list endpoints?: (freeform) no TTL; lists are not cached"
    "Q4 Cache warm-up on deploy?: superseded"
    "Q5 Shard keys by tenant?: reask  -- unclear what sharding means here"
    "open: Q6"
    "dropped: Q7 (Q3: lists are not cached)"
  ] | str join "\n")
}

def "test digest indents multi-line notes" [] {
  let out = (with-question Q3 {note: "line one\nline two"} | grill digest | lines | get 2)
  assert equal $out "Q3 TTL for list endpoints?: (freeform) line one"
}

def "test review order puts open first and dropped last" [] {
  assert equal (fixture | grill questions | grill review-order) [Q6 Q1 Q2 Q3 Q4 Q5 Q7]
}

def "test answer-for" [] {
  let q = (fixture | grill questions | where id == Q1 | first)
  assert equal ($q | grill answer-for pick b) {choice: b}
  assert equal ($q | grill answer-for pick c) null
  assert equal ($q | grill answer-for recommended) {choice: a}
  assert equal ($q | grill answer-for clear) {choice: "", note: ""}
  assert equal ($q | grill answer-for note "hi") {note: "hi"}
}

def "test review keys write the file and keep comments" [] {
  let f = (scratch)
  let order = (open $f | grill questions | grill review-order)
  # Q6 is first: b is not a rec (ignored), enter accepts a; then Q1 gets superseded; then a note on Q2.
  review ui $f $order | tui debug --keys [b enter down s down tab "type:only users" ctrl+s] | ignore
  let qs = (open $f | grill questions)
  assert equal ($qs | where id == Q6 | first | get choice) a
  assert equal ($qs | where id == Q1 | first | get choice) superseded
  assert equal ($qs | where id == Q2 | first | get note) "only users"
  let text = (open --raw $f)
  assert str contains $text "# fixture: a session after the user answered round 1"
  assert str contains $text "body = '''"
  rm $f
}

def "test review keeps questions appended while open" [] {
  let f = (scratch)
  let order = (open $f | grill questions | grill review-order)
  let ui = (review ui $f $order)
  open $f | merge {Q8: {round: 1, title: "New", body: "b", recommended: a, recs: {a: "x"}}} | to toml | save -f $f
  $ui | tui debug --keys [enter] | ignore
  let qs = (open $f | grill questions)
  assert equal ($qs | where id == Q8 | length) 1
  assert equal ($qs | where id == Q6 | first | get choice) a
  rm $f
}

const SELF = path self

def main [] {
  let tests = (scope commands | where name starts-with "test " | get name)
  let failures = ($tests | each {|t|
    let r = (^$nu.current-exe -c $"source '($SELF)'; ($t)" | complete)
    if $r.exit_code == 0 { print $"ok   ($t)"; null } else { print $"FAIL ($t)\n($r.stderr)"; $t }
  } | compact)
  if not ($failures | is-empty) { exit 1 }
}
