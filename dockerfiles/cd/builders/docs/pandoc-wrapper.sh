#!/usr/bin/env bash
set -euo pipefail

real_pandoc=/usr/bin/pandoc
horizontal_rule_filter=/usr/local/bin/pandoc-horizontal-rule-filter

pdf_output=false
expect_output_path=false

for arg in "$@"; do
  if [ "$expect_output_path" = true ]; then
    case "$arg" in
      *.pdf) pdf_output=true ;;
    esac
    expect_output_path=false
    continue
  fi

  case "$arg" in
    -o|--output)
      expect_output_path=true
      ;;
    --output=*.pdf)
      pdf_output=true
      ;;
  esac
done

if [ "$pdf_output" = true ]; then
  exec "$real_pandoc" --filter "$horizontal_rule_filter" "$@"
fi

exec "$real_pandoc" "$@"
