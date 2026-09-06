# shellcheck shell=bash

set -eu

PROBLEMS=''

while (($#)); do
    LINE="$(head -n 1 "$1")"
    if [[ "$LINE" =~ ^#! ]]; then
        if ! echo "$LINE" | grep -E -x -q '#!(@shebangs@)'; then
            echo "File '$1' has forbidden shebang '$LINE'" >&2
            PROBLEMS='t'
        fi
    fi
    shift
done

if [ -n "$PROBLEMS" ]; then
    exit 1
fi

exit 0
