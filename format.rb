#!/usr/bin/env ruby

words = ARGV.map!(&:downcase).reverse.uniq.reverse.join(" ").tr(",.", "")

puts words
