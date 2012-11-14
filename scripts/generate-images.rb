
require 'RMagick'
require 'yaml'

include Magick

#Procedure
# start with term
# extract definitions by part of speech
# generate metadata sequence of readable 'slides'
#  - word by itself
#  - word with first part of speech 
#  - word with first definition in first part of speech
#  - word with second definition in first part of speech ...
#  - word with second part of speech
#  - word with first def in second part of speech ...
#  - word by itself
#  - credits & licensing
# generate SubRip format closed caption file
# generate audio for each slide

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

slides = []
slides.push({
  'display' => term,
  'script' => term + '.'
})

defs.each { |kind, definitions|
  
  slides.push({
    'display' => term + "\n(" + kind + ")",
    'script' => 'Part of speech: ' + kind
  })
  
  puts "\n\n\n=== " + kind + " ===\n\n"
  
  i = 0
  for definition in definitions
    
    keep = true
    
    # ignore certain definitions
    keep = keep && (definition =~ /^{{(?:archaic|obsolete|dated)/).nil? #old
    #keep = keep && (definition =~ /^{{[A-Z]\w+/).nil? # country-specific
    #keep = keep && (definition =~ /^{{chiefly\|/).nil? # country-specific
    keep = keep && (definition =~ /^{{rf\w-(?:def|sense)/).nil? # unclear
    keep = keep && (definition =~ /{{rf(?:ex|def)[\|}]/).nil? # unclear
    
    if keep
      
      i += 1
      
      # convert wikitext into displayable definition
      display = definition
      
      # prefixes
      display = display.gsub(/^{{(in|un)?(transitive|formal|countable)[^\}]*}}/, '')
      display = display.gsub(/^{{([\w ]+)}}/, '(\1)')
      display = display.gsub(/^{{([\w ]+)\|chiefly\|[^\}]+}}/, '(\1)')
      display = display.gsub(/^{{([^\|\}]+ of)\|([^\}]+)}}/, '\1 "\2"')
      display = display.gsub(/^{{(\w+)\|_\|(\w+)}}/, '(\1 \2)')
      display = display.gsub(/^{{(computing|slang)(?:\|.*?)?}}/, '(\1)')
      display = display.gsub(/^{{senseid\|(?:[^\|]+\|)*([^}]+)}}/, '(\1)')
      display = display.gsub(/^{{(?:non-gloss definition|n-g)\|(.*?)}}/, '\1')
      
      # identifyable templates
      display = display.gsub(/{{([A-Z][^\|\}]+)[^\}]*}}/, '(\1)')
      display = display.gsub(/{{context(\|(in|un)?(formal|transitive))*}}/, '')
      display = display.gsub(/{{context\|(.*?)}}/, '(\1)')
      display = display.gsub(/{{taxlink\|([^\|]+)\|([^\|]+)}}/, '\1 \2')
      display = display.gsub(/{{(?:defdate|transitive|tritaxon)\|.*?}}/, '')
      display = display.gsub(/{{qualifier\|(.*?)}}/, '(\1)')
      
      # unidentifyable prefixes
      display = display.gsub(/^{{([^}]+)}}/, '(\1)')
      
      # link syntax
      display = display.gsub(/\[\[([^\]\|]+)\]\]/, '\1')
      display = display.gsub(/\[\[(?:[^\]\|]+\|)+([^\]]+)\]\]/, '\1')
      
      # emphasis
      display = display.gsub(/'''([\w ]+)'''/, '"\1"')
      display = display.gsub(/''(\w+)''/, '\1')
      display = display.gsub(/('+)([^']+)\1/, '\2')
      
      # punctuation and spacing
      display = display.gsub(/,(?:\s*,)+/, ',')
      display = display.gsub(/\|/, ', ')
      display = display.gsub(/\s+/, ' ')
      display = display.gsub(/^\s+|\s+$/, '')
      display = display.gsub(/\.*$/, '.')
      display = display.gsub(/\.+$/, '.')
      
      # capitalization
      display = display[0].upcase + display[1..-1]
      
      if !(display =~ /[\{\}\[\]]/).nil?
        puts '*****************************************************************'
        puts '* ' + definition
        puts '* ' + display
        puts '*****************************************************************'
      else
        puts display
      end
      
      # convert wikitext into speakable script
      script = definition
      script = ''
      
      slides.push({
        'display' =>
          term + " (" + kind + ")\n" +
          i.to_s + ". " + display,
        'script' =>
          'Definition ' + i.to_s + ': ' + script
      })
      
    end
    
  end
  
  if i == 0
    slides.pop
  end
  
}

puts "\n\n\n"

#https://en.wiktionary.org/w/api.php?action=query&prop=imageinfo&titles=File:en-us-{#term}.ogg&iiprop=url&format=json
#{"query":{"pages":{"-1":{"ns":6,"title":"File:en-us-tear-verb.ogg","missing":"","imagerepository":"shared","imageinfo":[{"url":"https:\/\/upload.wikimedia.org\/wikipedia\/commons\/b\/b2\/En-us-tear-verb.ogg","descriptionurl":"https:\/\/commons.wikimedia.org\/wiki\/File:En-us-tear-verb.ogg"}]}}}}

slides.push({
  'display' => term,
  'script' => term + '.'
})

#puts slides.to_yaml

exit

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


