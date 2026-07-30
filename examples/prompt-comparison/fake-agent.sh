#!/usr/bin/env bash

set -Eeuo pipefail

prompt="$(cat)"
mkdir -p output
if [[ "$prompt" == *"Write this exact value: candidate"* ]]; then
  printf 'candidate\n' > output/result.txt
else
  printf 'baseline\n' > output/result.txt
fi
