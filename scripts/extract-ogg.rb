#!ruby
# extract a sorted list of ogg files from the imagelinks SQL
# 
# Ex:
#  cat dumps/enwiktionary-latest-imagelinks.sql | ruby scripts/extract-ogg.rb
# 

audio_files = {}

STDIN.read.scan(/'([Ee]n-us-[^']+\.ogg)'/) { |match|
  k = match[0]
  k = k[0].upcase + k[1..-1]
  audio_files[k] = true
}

puts audio_files.keys.sort


