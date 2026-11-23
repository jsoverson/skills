# Print the compact answer list for a grilling session file.
use grill.nu

def main [file: path] {
  open $file | grill digest | print
}
