# Terminal UI for answering a grilling session file. Run it in a real terminal, not inside an agent session.
#
# Every key press re-reads the file, merges in the one change, and saves it, so questions an agent
# appends while the UI is open survive.
use grill.nu

const KEYS = "a-h pick  enter recommended  s superseded  r reask  x clear  tab note  ctrl+s save note  q quit"

# Merge answer fields into one question on disk. Stays a single pipeline from `open` so `to toml`
# keeps the file's comments and ''' strings.
def save-answer [file: path, id: string, fields: record] {
  open $file | merge deep {$id: $fields} | to toml | save -f $file
}

# Table rows for the UI, in a fixed order so the highlighted row stays put after an edit.
# Questions not in `order` (appended since launch) go last. Preview text is computed here because
# module commands are not reachable from inside a `tui preview` closure.
export def rows [file: path, order: list<string>] {
  let qs = (open $file | grill questions)
  let known = ($order | each {|id| $qs | where id == $id } | flatten)
  let added = ($qs | where id not-in $order)
  [...$known ...$added] | each {|q|
    let shown = (match $q.status {
      "accepted" => $q.choice
      "dropped" => "dropped"
      _ => $q.status
    })
    $q | insert shown $shown | insert text ($q | grill preview)
  }
}

# A hook that applies `action` to the highlighted question and returns the refreshed rows.
export def act [file: path, order: list<string>, action: string, value?: string] {
  {|s|
    let row = ($s.values.qs.row? | default null)
    if $row == null { return null }
    let value = (if $action == "note" { $s.values.note? | default "" } else { $value })
    let q = (open $file | grill questions | where id == $row.id)
    if ($q | is-empty) { return null }
    let fields = ($q | first | grill answer-for $action $value)
    if $fields == null { return null }
    save-answer $file $row.id $fields
    rows $file $order
  }
}

export def ui [file: path, order: list<string>] {
  let letters = [a b c d e f g h]
  let base = (rows $file $order
    | tui label --titlebar (open $file | get -o topic | default ($file | path basename))
    | tui split --sizes [45% 1fr] [
        (tui table --id qs --columns [id shown title] --focus)
        (tui split --vertical --sizes [1fr 3] [
          (tui preview --id pv --from qs {|q| $q.text })
          (tui textbox --id note --title "note (enter or ctrl+s saves)")
        ])
      ]
    | tui label --status $KEYS
    | tui bind enter (act $file $order recommended)
    | tui bind s (act $file $order superseded)
    | tui bind r (act $file $order reask)
    | tui bind x (act $file $order clear)
    | tui bind ctrl+s (act $file $order note))
  $letters | reduce --fold $base {|l, t| $t | tui bind $l (act $file $order pick $l) }
}

def main [file: path] {
  let errors = (open $file | grill validate)
  if not ($errors | is-empty) {
    $errors | each {|e| print $e } | ignore
    exit 1
  }
  let order = (open $file | grill questions | grill review-order)
  loop {
    let result = (ui $file $order | tui run)
    # Enter in the note box submits the whole UI; save the note and reopen.
    if $result.action == "submit" and $result.focused == "note" {
      let id = ($result.values.qs.row?.id? | default null)
      if $id != null { save-answer $file $id {note: ($result.values.note? | default "")} }
      continue
    }
    break
  }
  open $file | grill digest | print
}
