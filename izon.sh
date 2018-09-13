#!/bin/bash

function __readDependency() {
  local base_path="."
  if [[ $4 != "" ]]; then
    base_path=$4
  fi

  if [ -e $base_path/version.json ]; then
    local dependency=$1
    local url_var=$2
    local tag_var=$3
    local path=$(sed -n "/$dependency/p" $base_path/version.json | awk -F'"' '{print $4}')
    local url=$(echo $path | awk -F"#" '{print $1}')
    local tag=$(echo $path | awk -F"#" '{print $2}')

    eval $url_var="$url"
    eval $tag_var="$tag"
  else
    echo "Unable to find version.json file"
    exit 1
  fi
}

function __version() {
  local base_path="."
  if [ -n $1 ]; then
    base_path=$1
  fi
  local version=""
  if [ -e $base_path/VERSION ]; then
    version=$(cat VERSION)
  elif [ -e $base_path/version.json ]; then
    version=$(grep version version.json | cut -f 2 -d: | cut -f 2 -d \")
  else
    echo "Unable to find VERSION/version.json file"
    exit 1
  fi
}

function getVersionFile() {
    #if needed, get the version.json that resolves dependent repos from another github repo
  if [ ! -f "$VERSION_JSON" ]; then
    if [[ $currentDir == *"$REPO_NAME" ]]; then
      if [[ ! -f manifest.yml ]]; then
        echo "We noticed you are in a directory named $REPO_NAME but the usual contents (version.json) are not here, please rename the dir or do a git clone of the whole repo.  If you rename the dir, the script will get the repo."
        exit 1
      fi
    fi
    #echo $VERSION_JSON_URL
    curl -s -O $VERSION_JSON_URL
  fi
}

function getLocalSetupFuncs() {
  #get the predix-scripts url and branch from the version.json
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH
  LOCAL_SETUP_FUNCS_URL=https://raw.githubusercontent.com/PredixDev/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/scripts/local-setup-funcs.sh

  if [ -f "local-setup-funcs.sh" ]; then
    rm local-setup-funcs.sh
  fi
  if [ ! -f "local-setup-funcs.sh" ]; then
    curl -s -O $LOCAL_SETUP_FUNCS_URL
  fi
  source local-setup-funcs.sh
  getProxyScripts
}

function getProxyScripts() {
  #get the predix-scripts url and branch from the version.json
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH
  VERIFY_PROXY_URL=https://raw.githubusercontent.com/PredixDev/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/common/proxy/verify-proxy.sh
  TOGGLE_PROXY_URL=https://raw.githubusercontent.com/PredixDev/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/common/proxy/toggle-proxy.sh
  ENABLE_XSL_URL=https://raw.githubusercontent.com/PredixDev/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/common/proxy/enable-proxy.xsl
  DISABLE_XSL_URL=https://raw.githubusercontent.com/PredixDev/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/common/proxy/disable-proxy.xsl

  if [ -f "verify-proxy.sh" ]; then
    rm verify-proxy.sh
  fi
  if [ -f "toggle-proxy.sh" ]; then
    rm toggle-proxy.sh
  fi
  if [ -f "enable-proxy.xsl" ]; then
    rm enable-proxy.xsl
  fi
  if [ -f "disable-proxy.xsl" ]; then
    rm disable-proxy.xsl
  fi

  if [ ! -f "verify-proxy.sh" ]; then
    curl -s -O $VERIFY_PROXY_URL
  fi
  if [ ! -f "toggle-proxy.sh" ]; then
    curl -s -O $TOGGLE_PROXY_URL
  fi
  if [ ! -f "enable-proxy.xsl" ]; then
    curl -s -O $ENABLE_XSL_URL
  fi
  if [ ! -f "disable-proxy.xsl" ]; then
    curl -s -O $DISABLE_XSL_URL
  fi
  source verify-proxy.sh
}
