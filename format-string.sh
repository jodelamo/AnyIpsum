#!/usr/bin/env zsh

INPUT=$*:l
INPUT="${INPUT//.}"
INPUT="${INPUT//,}"

echo $INPUT
