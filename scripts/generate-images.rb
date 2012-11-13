
require 'RMagick'
require 'yaml'

include Magick

# Read input term from command line
term = ARGV[0]

# Extract terms from data dump
def extract_defs(term)
  
  # extract text definitions from TSV dump file
  data = `grep -P '^English\t#{term}\t' dumps/enwikt-defs-latest-en.tsv`

  # extract definitions per part of speech
  lines = data.split(/\r?\n/).map { |line| line.split(/\t/, 4).slice(2..-1) }
  defs = lines.inject(Hash.new{[]}) { |result, line|
    part = line[0].downcase
    result[part] = result[part].push(line[1].gsub(/^\s*#\s*/,''))
    result
  }
  
  return defs
  
end

# Generate image
def image_gen(term, definitions)
  for kind, defin in definitions
    # f = Image.new(800,500) { self.background_color = "white" }
    granite = Magick::ImageList.new('granite:')
    canvas = Magick::ImageList.new
    canvas.new_image(656, 492, Magick::TextureFill.new(granite))

    text = Magick::Draw.new
    # text.font_family = 'helvetica'
    text.pointsize = 52
    text.gravity = Magick::CenterGravity
    formatted_def = text_break(defin)
    formatted_def = "#{term.upcase}:\n#{formatted_def}"
    text.annotate(canvas, 0,0,0,0, formatted_def) {
      self.fill = 'black'
    }
    canvas.append(true).write("terms/#{term}/#{kind}.jpeg")
  end
end

def text_break(str)
  count=0
  new_str = ""
  str.split.each{|word|
    new_str += word
    if (count+=word.length+1) >= 20
      new_str += "\n"
      count = 0
    else
      new_str += " "
    end
  }
  new_str
end

# create slides
defs = extract_defs(term)
`mkdir -p terms/#{term}`

# for each part of speech, create a start slide
defs.each { |kind, definitions|
  i = 0
  for defin in definitions
    i += 1
    granite = Magick::ImageList.new('granite:')
    canvas = Magick::ImageList.new
    canvas.new_image(656, 492, Magick::TextureFill.new(granite))
    text = Magick::Draw.new
    # text.font_family = 'helvetica'
    text.pointsize = 52
    text.gravity = Magick::CenterGravity
    formatted_def = text_break(defin)
    formatted_def = "#{term.upcase}:\n#{formatted_def}"
    text.annotate(canvas, 0,0,0,0, formatted_def) {
      self.fill = 'black'
    }
    canvas.append(true).write("terms/#{term}/#{term}-#{kind}-#{i}.jpeg")
  end
}


