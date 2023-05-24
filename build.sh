#!/bin/bash
#
# Copyright (c) 2023 Red Hat, Inc.


# default branch of RoadieHQ/roadie-backstage-plugins to fetch
BRANCH="main"

# plugins to build
PLUGINS="\
frontend/backstage-plugin-argo-cd \
backend/backstage-plugin-argo-cd-backend \
"
usage () {
	echo "
Usage: fetch sources from https://github.com/RoadieHQ/roadie-backstage-plugins/ and build the ArgoCD plugins.

$0 -b BRANCH_TO_FETCH
$0 -b main
"
exit
}

if [[ $# -lt 1 ]]; then usage; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-b') BRANCH="$2"; shift 2;; 
  esac
done

if [[ -d roadie-backstage-plugins ]]; then rm -fr roadie-backstage-plugins; fi
git clone --branch "$BRANCH" --depth 1 https://github.com/RoadieHQ/roadie-backstage-plugins/ && pushd roadie-backstage-plugins >/dev/null || exit
mv plugins plugins_deleted; mkdir -p ../plugins/backend ../plugins/frontend; for p in $PLUGINS; do mv "plugins_deleted/$p" "../plugins/$p"; done; rm -fr plugins_deleted/;
popd >/dev/null || exit
if [[ -d roadie-backstage-plugins ]]; then rm -fr roadie-backstage-plugins; fi

echo "======= Included Plugins and Packages =======>";
for d in plugins/backend/* plugins/frontend/*; do
    if [[ -d $d ]]; then
    pushd "$d" >/dev/null || exit; 
        if [[ -f package.json ]]; then 
        echo -n "$d "; jq -r '.version' package.json; 
        fi; 
    popd >/dev/null || exit; 
    fi;
done;
echo "<======= Included Plugins and Packages =======";

# TODO now run the build 