#!ruby
# 
# Takes YAML for slides from STDIN and generates slide images.  Image paths
# are added back to slides and YAML pushed out to standard output
# 
# TODO:
#  - Only create image if the file doesn't already exist
#  - Add command line argument to force overwriting of files even if they exist
#  - Make image output location configurable
# 

require 'RMagick'
require 'yaml'

require './scripts/common.rb'

include Magick

# configuration
HPIXELS = 1280
VPIXELS = 720
IMAGE_KIND = 'png'
BACKGROUND = 'assets/bg2.png'
BODY_FONT = 'Goudy Bookletter 1911'
HEAD_FONT = 'Blue Highway' #'Eurostile'
BASE_FONT_SIZE = 82
HEAD_FONT_SIZE = 116 #96
BODY_FONT_SIZE = 78

# break text up for image generation
def text_break(str, width=38)
  new_str = ""
  count=0
  str.split.each{|word|
    if (count + word.length) >= width
      new_str += "\n" + word
      count = word.length
    else
      if count > 0
        new_str += " "
      end
      new_str += word
      count += word.length + 1
    end
  }
  new_str
end

# Add text to a canvas with the provided attributes
def annotate(draw, canvas, width, height, x, y, text, color='#16313f', shadow=true)
  if shadow
    draw.annotate(canvas, width, height, x+2, y+2, text) {
      self.fill = '#D0DDFF'
    }
  end
  draw.annotate(canvas, width, height, x, y, text) {
    self.fill = color
  }
end

# Generate image from a slide
def image_gen(slide)
  
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  body = slide['display'] || nil
  
  base = Magick::Image.read(BACKGROUND)[0]
  canvas = Magick::ImageList.new
  canvas.new_image(HPIXELS, VPIXELS, Magick::TextureFill.new(base))

  # heading
  heading = term
  heading_text = Magick::Draw.new
  heading_text.font_family = HEAD_FONT
  heading_text.pointsize = HEAD_FONT_SIZE
  heading_text.interline_spacing = -(HEAD_FONT_SIZE * 0.10)
  if kind
    if index
      heading += " (" + kind + ")"
    else
      heading += "\n(" + kind + ")"
    end
  end
  if index
    heading_text.gravity = Magick::NorthWestGravity
  else
    heading_text.gravity = Magick::CenterGravity
  end
  annotate(heading_text, canvas, 0,0,15,15, heading)
  
  # body
  if index
    body_text = Magick::Draw.new
    body_text.interline_spacing = -(BODY_FONT_SIZE * 0.20)
    body_text.font_family = BODY_FONT
    body_text.pointsize = BODY_FONT_SIZE
    body_text.gravity = Magick::NorthWestGravity
    body = text_break(body) #, 24)
    
    line_count = body.count("\n")
    if line_count > 5
      body = text_break(body, 44) #, 28)
      body_text.pointsize = BODY_FONT_SIZE - (line_count - 5) * 4
    end
    
    annotate(body_text, canvas, 0,0,40,110, body)
  end
  
  file_name = file_name_gen(slide, ".#{IMAGE_KIND}")
  
  # create path
  path = command_arg("terms/#{term}")
  `mkdir -p #{path}`
  
  canvas.append(true).write("#{file_name}")
  slide['image'] = file_name
  
end

presentation = YAML::load(STDIN.read)
slides = presentation['slides']

for slide in slides
  image_gen(slide)
end

puts presentation.to_yaml

