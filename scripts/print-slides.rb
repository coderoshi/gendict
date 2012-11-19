#!ruby
# 
# Takes YAML for slides from STDIN and dumps a human-inspectable console
# representation.
# 

require 'yaml'

# TODO: read all STDIN and produce slides array by parsing YAML

for slide in slides
  puts "\n************************************************************************************"
  puts "** " + slide['display'].gsub(/\n/, "\n** ")
  puts "************************************************************************************"
  image_gen(slide)
  audio_gen(slide)
  video_gen(slide)
end

