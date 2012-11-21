#!ruby
# 
# Takes YAML for slides from STDIN and generates slide video from previously
# generated image and audio files.  Video paths are added back to slides and
# YAML pushed out to standard output
# 
# TODO:
#  - Fix audio/video skew that occurs late in the combined video
#  - Only create video if the file doesn't already exist
#  - Add command line argument to force overwriting of files even if they exist
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
  `ffmpeg -loop 1 -y -i #{image} -i #{audio} -acodec libmp3lame -vcodec mpeg4 -shortest -qscale:v 1 #{video}`
  slide['video'] = file_name
end

# Concatenate slide videos together into one video
def combine_video(term, slides)
  concat = []
  for slide in slides
    concat.push slide['video']
  end
  concat = command_arg(concat.join('|'))
  combined = command_arg("terms/#{term}/#{term}_combined.avi")
  final = command_arg("terms/#{term}.avi")
  `ffmpeg -y -i concat:#{concat} -c copy #{combined}`
  `ffmpeg -y -i #{combined} -qscale:v 1 #{final}`
end

slides = YAML::load(STDIN.read)

for slide in slides
  video_gen(slide)
end

combine_video(slides[0]['term'], slides)

puts slides.to_yaml

