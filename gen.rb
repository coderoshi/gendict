require 'nokogiri'
require 'open-uri'
require 'RMagick'

include Magick

term = ARGV[0]

if term.nil?
  puts "usage: ruby gen.rb [TERM]"
  exit(0)
end

def get_definitions(term)
  def find_links(defin)
    defin = defin.to_s.strip
    defin.scan(/\[\[(.*?)\]\]/).first
  end

  def cleanup(defin)
    defin = defin.to_s
    defin.gsub(/\[\[(.*?)\]\]/, '\\1').gsub(/\{\{.*?\}\}/, '').gsub(/["]/, '').strip
  end

  data = `curl "http://en.wiktionary.org/w/index.php?action=raw&title=#{term}" 2> /dev/null`

  # english only
  language = data.match(%r{==English==(.+?)^(==\w)}m)[1] rescue nil
  language ||= data

  definitions = {}
  ids = %w{noun adjective}
  for id in ids
    defs = language.match(%r{===#{id}===(.+?)^(====?\w|---)}mi)[1] rescue nil
    next unless defs
    links = find_links(defs.match(/^\#(.*?)$/m)[1])
    definitions[id] = cleanup(defs.match(/^\#(.*?)$/m)[1])
  end
  definitions
end

# Generate audio
def audio_gen(term, definitions)
  # we can get the file name here, but not the upload location
  # audio = language.match(/\{\{audio\|([^\|\}]+).*?\}\}/)[1] rescue nil
  html = Nokogiri::HTML(open("http://en.wiktionary.org/wiki/#{term}"))
  audio = nil
  html.css('.audiofile audio source').each do |source|
    audio ||= source['src']
  end
  if audio
    audio = "http:#{audio}" if audio =~ /^\/\//
    `curl "#{audio}" -o "terms/#{term}/term.ogg" 2> /dev/null`
  else
    `say -o "terms/#{term}/term.aiff" "#{term}"`
  end

  for kind, defin in definitions
    `say -o "terms/#{term}/#{kind}.aiff" "#{kind}.. #{defin}"`
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

# Generate image
def image_gen(term, definitions)
  for kind, defin in definitions
    # f = Image.new(800,500) { self.background_color = "white" }
    # granite = Magick::ImageList.new('granite:')
    base = Magick::Image.read("assets/bg1.png")[0]
    canvas = Magick::ImageList.new
    canvas.new_image(1280, 720, Magick::TextureFill.new(base))

    text = Magick::Draw.new
    text.font_family = 'Goudy Bookletter 1911'
    text.pointsize = 52
    text.gravity = Magick::CenterGravity
    formatted_def = text_break(defin)
    formatted_def = "#{term.upcase}:\n#{formatted_def}"
    text.annotate(canvas, 0,0,0,0, formatted_def) {
      self.fill = 'black'
    }
    canvas.append(true).write("terms/#{term}/#{kind}.png")
  end
end

# Generate the video
def video_gen(term)
  `mkdir -p terms/#{term}`
  definitions = get_definitions(term)
  # audio_gen(term, definitions)
  image_gen(term, definitions)

  # ffmpeg -y -loop 1 -r 1 -i noun.png -acodec copy -i noun.aiff -shortest thisvid.mp4
end


video_gen(term)
