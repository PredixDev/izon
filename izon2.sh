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

function getUsingCurl() {
  if [ -z $1 ]; then
    echo "Link not passed"
    exit 1
  fi
  
  if [[ $1 = *"github.build.ge"* ]]; then
    echo $GITHUB_BUILD_TOKEN 111
    if [[ -n "$GITHUB_BUILD_TOKEN" ]]; then
      SHORT_LINK=${1##*//}
      URL="https://$GITHUB_BUILD_TOKEN@$SHORT_LINK"
      echo "Downloading the file $1"
      curl -s -O $URL
      if [ $? -ne 0 ]; then
        echo "Please check proxy env vars, e.g. HTTP_PROXY and HTTPS_PROXY"
        exit 1
      fi
    else 
      echo "Please ensure env var GITHUB_BUILD_TOKEN for github.build.ge.com token is set" 
      exit 1  
    fi
  else
    echo "Downloading the file $1"
    curl -s -O $1
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
    echo $VERSION_JSON_URL
    getUsingCurl $VERSION_JSON_URL
    cat version.json
  fi
}

function getLocalSetupFuncs() {
  #get the predix-scripts url and branch from the version.json
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH
  LOCAL_SETUP_FUNCS_URL="$GITHUB_RAW/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/scripts/local-setup-funcs.sh"
  # Getting the proxy scripts
  getProxyScripts $GITHUB_RAW
  # Deleting any old file and downloading a new one
  rm -rf local-setup-funcs.sh
  getUsingCurl $LOCAL_SETUP_FUNCS_URL
  source local-setup-funcs.sh
}

function getProxyScripts() {
  GITHUB_RAW=$1
  #get the predix-scripts url and branch from the version.json
  __readDependency $PREDIX_SCRIPTS PREDIX_SCRIPTS_URL PREDIX_SCRIPTS_BRANCH
  VERIFY_PROXY_URL="$GITHUB_RAW/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/common/proxy/verify-proxy.sh"
  TOGGLE_PROXY_URL="$GITHUB_RAW/$PREDIX_SCRIPTS/$PREDIX_SCRIPTS_BRANCH/bash/common/proxy/toggle-proxy.sh"
  # Deleting any old files and downloading new ones
  rm -rf verify-proxy.sh
  rm -rf toggle-proxy.sh
  getUsingCurl $VERIFY_PROXY_URL
  getUsingCurl $TOGGLE_PROXY_URL
  echo
  echo "Verifying proxy settings using verify-proxy.sh"
  chmod 755 verify-proxy.sh
  ./verify-proxy.sh
}
