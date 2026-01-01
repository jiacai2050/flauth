#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

version=$(git tag --points-at HEAD)
if [ -z "$version" ]; then
    if [ $# -gt 0 ]; then
        version=$1
    else
        echo  "No git tag found for the current commit. Please create a tag before releasing."
        exit 1
    fi
fi

target_file="/tmp/flauth-macos-$version.zip"
echo "Releasing version $version"
echo "Building macOS release..."
flutter build macos --release
echo "Build completed."

echo "Packaging release into $target_file ..."
pushd "${script_dir}/build/macos/Build/Products/Release/"
zip -r "$target_file" "flauth.app"
popd

echo "macOS release packaged at $target_file"
