#! /bin/bash

error=
for f in tests/*; do
  if ! ./"$f"; then
    error=YES
  fi
done

if [[ "$error" == YES ]]; then
  exit 1
fi
