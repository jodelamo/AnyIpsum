#!/bin/bash
#
# Example usage:
#
#    ./add-variation.sh "Lorem Ipsum" source.txt
#
# Where "Lorem Ipsum" is the name of the variation, and "source.txt" is the
# file to read words from. The results will be appended to the list of
# variations in `AnyIpsum/Ipsum.plist`. Note that newlines in the source file
# will be used as word delimiters.

if [ $# -lt 2 ]; then
  exit 1
fi

# Shortcut to PlistBuddy binary
plistbuddy="/usr/libexec/plistbuddy"

# Name of the plist dictionary
name=$1

# File with words
source=$(cat "$2")

# Target file
target="Ipsum.plist"

# Loop through words. For every encountered newline, add that row as an entry
# in the array of lorem ipsum variations.
$plistbuddy -c "Add :\"$name\" array" $target

IFS=$'\n'
for word in $source; do
  $plistbuddy -c "Add :\"$name\": string \"$word\"" $target
done
