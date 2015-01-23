#! /bin/bash

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  brew update
  brew install zsh
else
  sudo apt-get update
  sudo apt-get install -qq -y bc zsh
fi
