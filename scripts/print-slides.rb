#!ruby
# 
# Takes YAML for slides from STDIN and dumps a human-inspectable console
# representation.
# 

require 'yaml'

slides = YAML::load(STDIN.read)

for slide in slides
  puts "\n************************************************************************************"
  puts "** " + slide['display'].gsub(/\n/, "\n** ")
  puts "************************************************************************************"
end

