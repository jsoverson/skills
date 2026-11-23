# Check a grilling session file. Prints one error per line and exits 1 on any error.
use grill.nu

def main [file: path] {
  let errors = (open $file | grill validate)
  if ($errors | is-empty) {
    print $"ok: ($file)"
  } else {
    $errors | each {|e| print $e } | ignore
    exit 1
  }
}
