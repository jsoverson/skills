# Pure functions over a parsed grilling session record (the output of `open session.toml`).

const KEYWORDS = [superseded reask]

# The numeric part of a question id: Q13 -> 13. Null when the key is not a question id.
export def qnum []: string -> any {
  let m = ($in | parse --regex '^Q(?<n>[0-9]+)$')
  if ($m | is-empty) { null } else { $m.0.n | into int }
}

def str-or-empty []: any -> string {
  if $in == null { "" } else { $in | into string }
}

# Status derived from choice, note, and dropped.
# One of: open, accepted, answered, superseded, reask, dropped.
export def status []: record -> string {
  let q = $in
  let choice = ($q.choice? | str-or-empty)
  let note = ($q.note? | str-or-empty)
  match $choice {
    "superseded" => "superseded"
    "reask" => "reask"
    "" => {
      if $note != "" { "answered" } else if ($q.dropped? | str-or-empty) != "" { "dropped" } else { "open" }
    }
    _ => "accepted"
  }
}

# Questions as a table sorted by id, with every field present.
export def questions []: record -> table {
  let doc = $in
  $doc
  | transpose key value
  | where {|r| ($r.key | qnum) != null }
  | each {|r|
      let q = $r.value
      let row = {
        id: $r.key
        n: ($r.key | qnum)
        round: ($q.round? | default 0)
        title: ($q.title? | str-or-empty)
        body: ($q.body? | str-or-empty)
        recs: ($q.recs? | default {})
        recommended: ($q.recommended? | str-or-empty)
        choice: ($q.choice? | str-or-empty)
        note: ($q.note? | str-or-empty)
        dropped: ($q.dropped? | str-or-empty)
        replaces: ($q.replaces? | str-or-empty)
      }
      $row | insert status ($row | status)
    }
  | sort-by n
}

# Validation errors for a session record, one string per error. Empty when valid.
export def validate []: record -> list<string> {
  let doc = $in
  let qs = ($doc | questions)
  let rounds = ($doc.round? | default {} | columns)
  let ids = ($qs | get id)

  let top = ($doc | columns | where {|k| ($k | qnum) == null and $k not-in [topic goal round] }
    | each {|k| $"($k): unknown top-level key; questions are named Q<n>" })

  let header = ([topic goal] | where {|k| ($doc | get -o $k | str-or-empty) == "" }
    | each {|k| $"($k): missing" })

  let sequence = ($qs | enumerate | where {|e| $e.item.n != ($e.index + 1) }
    | first 1
    | each {|e| $"($e.item.id): ids must run Q1, Q2, ... without gaps; expected Q($e.index + 1)" })

  let per_question = ($qs | each {|q|
    let letters = ($q.recs | columns)
    [
      (if $q.round == 0 { "round is missing" })
      (if $q.round != 0 and ($q.round | into string) not-in $rounds { $"round ($q.round) has no [round.($q.round)] table" })
      (if $q.title == "" { "title is missing" })
      (if $q.body == "" { "body is missing" })
      (if ($letters | is-empty) { "needs at least one rec" })
      ($letters | where {|l| $l !~ '^[a-h]$' } | each {|l| $"rec '($l)' must be a single letter a-h" })
      (if $q.recommended == "" { "recommended is missing" })
      (if $q.recommended != "" and $q.recommended not-in $letters { $"recommended '($q.recommended)' is not a rec" })
      (if $q.choice != "" and $q.choice not-in $letters and $q.choice not-in $KEYWORDS {
        $"choice '($q.choice)' must be empty, a rec letter, superseded, or reask"
      })
      (if $q.replaces != "" and $q.replaces not-in $ids { $"replaces '($q.replaces)' does not exist" })
      (if $q.replaces != "" and $q.replaces in $ids and ($qs | where id == $q.replaces | first | get choice) != "reask" {
        $"replaces '($q.replaces)', which is not marked reask"
      })
    ]
    | flatten
    | compact
    | each {|e| $"($q.id): ($e)" }
  } | flatten)

  [$top $header $sequence $per_question] | flatten
}

def indent-rest []: string -> string {
  $in | lines | str join "\n    "
}

def digest-line []: record -> string {
  let q = $in
  let note = (if $q.note == "" { "" } else { $"  -- ($q.note | indent-rest)" })
  match $q.status {
    "accepted" => {
      let rec = ($q.recs | get -o $q.choice | str-or-empty)
      $"($q.id) ($q.title): [($q.choice)] ($rec | indent-rest)($note)"
    }
    "answered" => $"($q.id) ($q.title): (char lparen)freeform(char rparen) ($q.note | indent-rest)"
    _ => $"($q.id) ($q.title): ($q.status)($note)"
  }
}

# Compact answer list: one line per answered question, then open and dropped ids.
export def digest []: record -> string {
  let qs = ($in | questions)
  let answered = ($qs | where status not-in [open dropped] | each { digest-line })
  let open = ($qs | where status == open | get id)
  let dropped = ($qs | where status == dropped | each {|q| $"($q.id) (char lparen)($q.dropped)(char rparen)" })
  [
    ...$answered
    $"open: (if ($open | is-empty) { 'none' } else { $open | str join ', ' })"
    ...(if ($dropped | is-empty) { [] } else { [$"dropped: ($dropped | str join ', ')"] })
  ] | str join "\n"
}

# Order for the review table: open first, dropped last, then by id.
export def review-order []: table -> list<string> {
  let rank = {open: 0, reask: 1, answered: 1, accepted: 1, superseded: 1, dropped: 2}
  $in | sort-by {|q| [($rank | get $q.status) $q.n] } | get id
}

# The fields an action writes, or null when the action does not apply to the question.
export def answer-for [action: string, value?: string]: record -> any {
  let q = $in
  match $action {
    "pick" => { if $value in ($q.recs | columns) { {choice: $value} } }
    "recommended" => { if $q.recommended != "" { {choice: $q.recommended} } }
    "superseded" => {choice: "superseded"}
    "reask" => {choice: "reask"}
    "clear" => {choice: "", note: ""}
    "note" => {note: ($value | default "")}
    _ => null
  }
}

# Preview text for one question row.
export def preview []: record -> string {
  let q = $in
  let recs = ($q.recs | transpose letter text | each {|r|
    let mark = (if $r.letter == $q.choice { ">" } else { " " })
    let star = (if $r.letter == $q.recommended { "*" } else { " " })
    $"($mark)($star)($r.letter)) ($r.text)"
  })
  [
    $"($q.id), round ($q.round): ($q.title)"
    ""
    ($q.body | str trim)
    ""
    ...$recs
    ""
    $"status: ($q.status)(if $q.choice in [superseded reask] { '' } else if $q.choice != '' { $' [($q.choice)]' } else { '' })"
    ...(if $q.note == "" { [] } else { [$"note: ($q.note)"] })
    ...(if $q.dropped == "" { [] } else { [$"dropped: ($q.dropped)"] })
    ...(if $q.replaces == "" { [] } else { [$"replaces: ($q.replaces)"] })
  ] | str join "\n"
}
