#!/usr/bin/env bash

set -eu -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $SCRIPT_DIR/..

version=${1:-}
if [[ -z "$version" ]]; then
  echo "USAGE: $0 version" >&2
  exit 1
fi

if [[ "$(git symbolic-ref --short HEAD)" != "master" ]]; then
  echo "must be on master branch" >&2
  exit 1
fi

# ensure we are up-to-date
uncommited_changes=$(git diff --compact-summary)
if [[ -n "$uncommited_changes" ]]; then
  echo -e "There are uncommited changes, exiting:\n${uncommited_changes}" >&2
  exit 1
fi
git pull git@github.com:Mic92/nixpkgs-review master
unpushed_commits=$(git log --format=oneline origin/master..master)
if [[ "$unpushed_commits" != "" ]]; then
  echo -e "\nThere are unpushed changes, exiting:\n$unpushed_commits" >&2
  exit 1
fi
sed -i -e "s!version=\".*\"!version=\"${version}\"!" setup.py
git add setup.py
nix-build --builders '' default.nix
git commit -m "bump version ${version}"
git tag -e "${version}"

echo 'now run `git push --tags origin master`'
