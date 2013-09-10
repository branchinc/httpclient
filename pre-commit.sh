#!/bin/sh

# To install, run `ln ./pre-commit.sh .git/hooks/pre-commit` at the root

echo "Compiling Coffee to JS"
./node_modules/coffee-script/bin/coffee -o out/ -c src/
git add out
