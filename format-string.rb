#!/usr/bin/env ruby

words = ARGV.uniq.join(' ').downcase.tr(',.', '')

puts words
