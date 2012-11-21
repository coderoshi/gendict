#!ruby
# 
# Takes YAML for slides from STDIN and generates slide video from previously
# generated image and audio files.  Video paths are added back to slides and
# YAML pushed out to standard output
# 
# TODO:
#  - Make video output location configurable
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

# Generate video for a slide by combining the image and audio
def video_gen(slide)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = file_name_gen(slide, ".avi")
  audio = command_arg(slide['audio'])
  image = command_arg(slide['image'])
  video = command_arg(file_name)
  `ffmpeg -loop 1 -y -i #{image} -i #{audio} -acodec libmp3lame -vcodec mpeg4 -shortest -sameq #{video}`
  slide['video'] = file_name
end

slides = YAML::load(STDIN.read)

for slide in slides
  video_gen(slide)
end

puts slides.to_yaml

