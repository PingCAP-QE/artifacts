#!/usr/bin/env python3
"""Pandoc filter to replace horizontal rules with LaTeX rule in PDF output."""

import json
import sys

HRULE_LATEX = r"\begin{center}\rule{0.5\linewidth}{0.4pt}\end{center}"


def transform(node):
    if isinstance(node, list):
        return [transform(item) for item in node]
    if isinstance(node, dict):
        if node.get("t") == "HorizontalRule":
            return {"t": "RawBlock", "c": ["latex", HRULE_LATEX]}
        return {key: transform(value) for key, value in node.items()}
    return node


def main():
    document = json.load(sys.stdin)
    json.dump(transform(document), sys.stdout, separators=(",", ":"))


if __name__ == "__main__":
    main()
