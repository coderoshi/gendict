#!ruby
# 
# Given a term on the command line, generate a video from end-to-end, or treat
# STDIN as a list of terms to generate.
# 

require 'yaml'
require './scripts/common.rb'

term = ARGV[0]

if term.nil?
  terms = STDIN.read.split("\n")
else
  terms = [term]
end

index = 0

terms.each do |term|

  index += 1
  puts "=============== GENERATING TERM #{index} of #{terms.length}: #{term} ==============="

  term_arg = command_arg(term)
  dist_dir = command_arg("#{DIST_DIR}/#{term}")
  yaml_file = command_arg("#{DIST_DIR}/#{term}/#{term}.yaml")

  procedure = [
    "ruby scripts/make-slides.rb #{term_arg}",
    "ruby scripts/make-images.rb",
    "ruby scripts/make-audio.rb",
    "ruby scripts/make-video.rb",
    "ruby scripts/upload-video.rb",
  ].join(' | ') + " > #{yaml_file}"

  puts "Running procedure: #{procedure}"
  `mkdir -p #{dist_dir}`
  `#{procedure}`

end


