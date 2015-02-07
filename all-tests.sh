#! /bin/bash

if [[ "$1" == "" ]]; then
  shell=bash
elif grep "$1" /etc/shells 2>/dev/null 1>/dev/null; then
  shell="$1"
  shift
else
  shell=bash
fi
if [[ "$1" == "" ]]; then
  files="tests/*.sh"
else
  files="$@"
fi

if [[ "$shell" == "zsh" ]];then
  shell="zsh -y"
fi

error=
mkdir -p work
for f in $files; do
  n=work/$(basename "$f")
  sed "1s/.*/#!\/bin\/${shell}/" "$f" > "$n"
  chmod +x "$n"
  if ! ./"$n"; then
    error=YES
  fi
done

if [[ "$error" == YES ]]; then
  exit 1
fi
