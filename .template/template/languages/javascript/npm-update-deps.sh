# shellcheck shell=bash

set -eu

npm outdated --parseable |
    cut -d : -f 4 |
    xargs npm install --save-exact

rm -f package-lock.json
rm -rf node_modules
npm install
