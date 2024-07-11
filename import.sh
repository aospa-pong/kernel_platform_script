#!/bin/bash

# Function to add color
colorize() {
  echo -e "\033[$1m$2\033[0m"
}

# Prompt to change directory
read -p "$(colorize '1;34' 'Enter the directory where the script should run: ')" target_dir
if [ ! -d "$target_dir" ]; then
  mkdir -p "$target_dir"
  colorize '1;32' "Directory $target_dir created."
fi

cd "$target_dir" || { colorize '1;31' "Failed to change to directory $target_dir. Exiting."; exit 1; }

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
  git init
  git commit --allow-empty -m "modules: Initial empty repository"
  colorize '1;32' "Initialized empty git repository and made initial commit."
fi

# Function to get the latest tag from a remote repository
get_latest_tag() {
  url=$1
  prefix=$2

  # Fetch all tags from the remote and extract relevant versions
  git ls-remote --tags $url | grep -o 'refs/tags/[^\^]*' | awk -F/ '{print $3}' | grep "$prefix" | grep "WAIPIO" | sort -t'-' -k4 -V | tail -1
}

# Function to check if remote exists and update or add it
add_or_update_remote() {
  prefix=$1
  url=$2

  existing_url=$(git remote get-url $prefix 2>/dev/null)
  if [ $? -eq 0 ]; then
    if [ "$existing_url" != "$url" ]; then
      git remote remove $prefix
      git remote add $prefix $url
      colorize '1;33' "Updated remote $prefix to $url"
    else
      colorize '1;33' "Remote $prefix with URL $url already exists, skipping."
    fi
  else
    git remote add $prefix $url
    colorize '1;33' "Added remote $prefix with URL $url"
  fi
}

# Prompt user to find the latest tags or enter manually
read -p "$(colorize '1;34' 'Do you want to find the latest tags automatically? (yes/no): ')" find_latest_tags
find_latest_tags=${find_latest_tags:-yes}

case $find_latest_tags in
  [Yy]* | [Yy][Ee][Ss]*) find_latest_tags="yes" ;;
  [Nn]* | [Nn][Oo]*) find_latest_tags="no" ;;
  *) find_latest_tags="yes" ;;
esac

declare -A tags

if [ "$find_latest_tags" == "no" ]; then
  # Prompt for tags with examples
  read -p "$(colorize '1;34' 'Enter WAIPIO tag (e.g., LA.VENDOR.1.0.r1-25500-WAIPIO.QSSI14.0): ')" WAIPIO
  tags["WAIPIO"]=${WAIPIO:-LA.VENDOR.1.0.r1-25500-WAIPIO.QSSI14.0}

  read -p "$(colorize '1;34' 'Enter CAMERA tag (e.g., CAMERA.LA.2.0.r1-11800-WAIPIO.0): ')" CAMERA
  tags["CAMERA"]=${CAMERA:-CAMERA.LA.2.0.r1-11800-WAIPIO.0}

  read -p "$(colorize '1;34' 'Enter DISPLAY tag (e.g., DISPLAY.LA.2.0.r1-13000-WAIPIO.0): ')" DISPLAY
  tags["DISPLAY"]=${DISPLAY:-DISPLAY.LA.2.0.r1-13000-WAIPIO.0}

  read -p "$(colorize '1;34' 'Enter VIDEO tag (e.g., VIDEO.LA.2.0.r1-10200-WAIPIO.0): ')" VIDEO
  tags["VIDEO"]=${VIDEO:-VIDEO.LA.2.0.r1-10200-WAIPIO.0}
else
  tags=(
    ["CAMERA"]="CAMERA.LA.2.0.r1-"
    ["DISPLAY"]="DISPLAY.LA.2.0.r1-"
    ["VIDEO"]="VIDEO.LA.2.0.r1-"
    ["WAIPIO"]="LA.VENDOR.1.0.r1-"
  )
fi

repos=(
  "audio-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/audio-kernel-ar.git WAIPIO"
  "camera-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/camera-kernel.git CAMERA"
  "cvp-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/cvp-kernel WAIPIO"
  "dataipa https://git.codelinaro.org/clo/la/platform/vendor/opensource/dataipa.git WAIPIO"
  "datarmnet-ext https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet-ext.git WAIPIO"
  "datarmnet https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet.git WAIPIO"
  "display-drivers https://git.codelinaro.org/clo/la/platform/vendor/opensource/display-drivers.git DISPLAY"
  "eva-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/eva-kernel.git WAIPIO"
  "mmrm-driver https://git.codelinaro.org/clo/la/platform/vendor/opensource/mmrm-driver.git VIDEO"
  "video-driver https://git.codelinaro.org/clo/la/platform/vendor/opensource/video-driver.git VIDEO"
  "wlan/fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api.git WAIPIO"
  "wlan/qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0.git WAIPIO"
  "wlan/qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn.git WAIPIO"
)

process_repo() {
  local prefix=$1
  local url=$2
  local tag_prefix=$3

  # Add or update remote
  add_or_update_remote $prefix $url

  if [ "$find_latest_tags" == "yes" ]; then
    # Get the latest tag from the remote
    latest_tag=$(get_latest_tag $url "${tags[$tag_prefix]}")

    # Skip if no valid tag is found
    if [ -z "$latest_tag" ]; then
      colorize '1;31' "No valid tags found for $prefix with prefix ${tags[$tag_prefix]} containing 'WAIPIO'"
      return
    fi
  else
    latest_tag=${tags[$tag_prefix]}
  fi

  colorize '1;32' "Using tag $latest_tag for $prefix"

  if [ -d "$prefix" ]; then
    colorize '1;33' "Directory $prefix exists. Using merge method."
    git pull -s subtree -Xsubtree=$prefix $url $latest_tag --log
  else
    colorize '1;33' "Directory $prefix does not exist. Using import method."
    git subtree add --prefix=$prefix $url $latest_tag -m "$prefix: Import from $latest_tag"
  fi
}

for repo in "${repos[@]}"; do
  IFS=' ' read -r prefix url tag_prefix <<< "$repo"
  process_repo $prefix $url $tag_prefix
done
