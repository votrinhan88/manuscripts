#!/bin/bash
# Remove LaTeX temporary files recursively

find . -type f \( \
  -name "*.aux" \
  -o -name "*.log" \
  -o -name "*.toc" \
  -o -name "*.out" \
  -o -name "*.bbl" \
  -o -name "*.bbl-SAVE-ERROR" \
  -o -name "*.blg" \
  -o -name "*.fdb_latexmk" \
  -o -name "*.fls" \
  -o -name "*.run.xml" \
  -o -name "*.lof" \
  -o -name "*.lot" \
  -o -name "*.bcf" \
  -o -name "*.bcf-SAVE-ERROR" \
  -o -name "*.synctex" \
  -o -name "*.synctex.gz" \
  -o -name "*.nav" \
  -o -name "*.snm" \
  -o -name "*.vrb" \
  -o -name "*.xdv" \
\) -delete

echo "[OK] Cleaned LaTeX temporary files"
