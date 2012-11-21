#!ruby
# 
# Takes YAML for slides from STDIN and generates slide audio.  Audio paths
# are added back to slides and YAML pushed out to standard output
# 
# TODO:
#  - Make audio output location configurable
#  - Move common functionality like file_name_gen() to separate Module
# 

require 'yaml'

# Make a given argument safe for inserting into a command-line
def command_arg(arg)
  "'" + arg.gsub(/[\']/, "'\\\\''") + "'"
end

# Generate a filename for a given slide and suffix
def file_name_gen(slide, suffix)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = "terms/#{term}/#{term}"
  if kind
    file_name += "-#{kind}"
    if index
      file_name += "-#{index}"
    end
  end
  file_name + suffix
end

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

