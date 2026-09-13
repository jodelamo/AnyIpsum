#!/bin/bash

set -euo pipefail

version="${1:?Usage: update-marketing-version.sh VERSION}"
project="AnyIpsum.xcodeproj/project.pbxproj"

perl -0pi -e "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $version;/g" "$project"
