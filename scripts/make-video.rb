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
# 

require 'yaml'

require './scripts/common.rb'

# Generate video for a slide by combining the image and audio
def video_gen(slide)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = file_name_gen(slide, ".mpg")
  audio = command_arg(slide['audio'])
  image = command_arg(slide['image'])
  video = command_arg(file_name)
  `ffmpeg -loop 1 -y -i #{image} -i #{audio} -acodec libmp3lame -vcodec mpeg4 -shortest -qscale:v 1 #{video}`
  slide['video'] = file_name
end

# Concatenate slide videos together into one video
def combine_video(presentation)
  term = presentation['term']
  args = []
  for slide in presentation['slides']
    args.push command_arg(slide['video'])
  end
  args = args.join(' ')
  combined_arg = command_arg("#{BUILD_DIR}/#{term}/#{term}-combined.mpg")
  final = "#{DIST_DIR}/#{term}/#{term}.avi"
  final_arg = command_arg(final)
  `cat #{args} > #{combined_arg}`
  `ffmpeg -y -i #{combined_arg} -r 25 -qscale:v 1 #{final_arg}`
  presentation['video'] = final
end

presentation = YAML::load(STDIN.read)
slides = presentation['slides']
term = presentation['term']

# create build and dist paths
build_path = command_arg("#{BUILD_DIR}/#{term}")
`mkdir -p #{build_path}`
dist_path = command_arg("#{DIST_DIR}/#{term}")
`mkdir -p #{dist_path}`

for slide in slides
  video_gen(slide)
end

combine_video(presentation)

puts presentation.to_yaml

