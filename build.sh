#!/bin/bash
#
# Copyright (c) 2023 Red Hat, Inc.


# default branch of RoadieHQ/roadie-backstage-plugins to fetch
BRANCH="main"
NAMESPACE="janus-idp"
CLEAN=1 # clean up node_modules and anything from remote repo

# plugins to build
PLUGINS="\
frontend/backstage-plugin-argo-cd \
backend/backstage-plugin-argo-cd-backend \
"
usage () {
	echo "
Usage: fetch sources from https://github.com/RoadieHQ/roadie-backstage-plugins/ and build the ArgoCD plugins.

Options:
    -b BRANCH_TO_FETCH          set which branch to fetch; default 'main'
    -n NEW_NAMESPACE            set new @namespace for plugins; default '@janus-idp'
    --no-clean                  do not clean up from previous builds; default clean up before/after

Example:

    $0 -b main -n redhat
"
exit
}

if [[ $# -lt 1 ]]; then usage; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-b') BRANCH="$2"; shift 2;;
    '-n') NAMESPACE="$2"; shift 2;; # eg., @janus-idp or @redhat
    '--no-clean') CLEAN=0; shift 1;;
  esac
done

# cleanup in advance
if [[ $CLEAN -eq 1 ]]; then
    rm -fr roadie-backstage-plugins plugins packages node_modules
    git clone --branch "$BRANCH" --depth 1 https://github.com/RoadieHQ/roadie-backstage-plugins/
fi

pushd roadie-backstage-plugins >/dev/null || exit
    mv plugins plugins_deleted
    mkdir -p ../plugins/backend ../plugins/frontend
    for p in $PLUGINS; do mv "plugins_deleted/$p" "../plugins/$p"; done
    rm -fr plugins_deleted/
popd >/dev/null || exit

# remove checked out files
if [[ $CLEAN -eq 1 ]]; then rm -fr roadie-backstage-plugins; fi

echo "======= Included Plugins and Packages =======>"
for d in plugins/backend/* plugins/frontend/*; do
    if [[ -d $d ]]; then
    pushd "$d" >/dev/null || exit
        if [[ -f package.json ]]; then 
            echo -n "$d "; jq -r '.version' package.json
        fi
    popd >/dev/null || exit
    fi
done
echo "<======= Included Plugins and Packages ======="; echo

# build the plugins
#shellcheck disable=SC2044
for d in plugins/backend/* plugins/frontend/*; do
    if [[ -d $d ]]; then
    pushd "$d" >/dev/null || exit
        if [[ -f package.json ]]; then 
            echo -n "$d "; jq -r '.version' package.json

            # TODO change ref from nickboldt/argocd to janus-idp/argocd
            # change from @roadiehq to @janus-idp or @redhat
            echo -n "Converting $(find . -name package.json -o -name "*.md" -o -name "*.ts*" | wc -l) files to @${NAMESPACE}"
            c=0
            for f in $(find . -name package.json -o -name "*.md" -o -name "*.ts*"); do 
                sed -r -e "s|@roadiehq|@${NAMESPACE}|g" -e "s|github:RoadieHQ/roadie-backstage-plugins|github:nickboldt/argocd|g" -i "$f"
                (( c = c + 1 ))
                if ! (( c % 250 )); then echo -n "."; fi
            done
            echo " done."

            yarn config set "strict-ssl" false; # yarn config list --verbose; 
            echo -n "Yarn version: "; yarn --version; echo;
            yarn install --frozen-lockfile # --ignore-scripts
            yarn build
            echo
        fi
    popd >/dev/null || exit
    fi
done
