#!ruby
# 
# Takes YAML for slides from STDIN and generates slide audio.  Audio paths
# are added back to slides and YAML pushed out to standard output
# 
# TODO:
#  - Only create audio file if the file doesn't already exist
#  - Add command line argument to force overwriting of files even if they exist
#  - Make audio output location configurable
# 

require 'yaml'

require './scripts/common.rb'

# Generate text-to-speech reading of slide script
def audio_gen(slide)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = file_name_gen(slide, ".WAV")
  say = command_arg('[[slnc 1000]]' + slide['script'] + '[[slnc 1000]]')
  output = command_arg(file_name)
  `say -v Jill #{say} -o #{output}`
  slide['audio'] = file_name
end

slides = YAML::load(STDIN.read)

for slide in slides
  audio_gen(slide)
end

puts slides.to_yaml

