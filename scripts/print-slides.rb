#!ruby
# 
# Takes YAML for slides from STDIN and dumps a human-inspectable console
# representation.
# 

require 'yaml'

presentation = YAML::load(STDIN.read)
slides = presentation['slides']

for slide in slides
  puts "\n************************************************************************************"
  puts "** " + slide['display'].gsub(/\n/, "\n** ")
  puts "************************************************************************************"
end

