
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

# Extract terms from data dump
def extract_defs(term)
  
  # create shell-safe term
  safe_term = term
  safe_term = safe_term.gsub(/([\-\[\]\{\}\(\)\*\+\?\.\,\\\^\$\|\#])/, '\\\\\\1')
  safe_term = safe_term.gsub(/[\']/, "'\\\\''")
  
  # extract text definitions from TSV dump file
  data = `grep -P '^English\\t#{safe_term}\\t' dumps/enwikt-defs-latest-en.tsv`

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

# break text up for image generation
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

def clean_defs(term, defs)
  buf = ""
  defs.each { |kind, definitions|
    
    buf += "=== " + kind + " ===\n"
    
    i = 0
    for definition in definitions
      
      keep = true
      
      # ignore old and unclear definitions
      keep = keep && (definition =~ /{{(?:[^}]+\|)?(?:archaic|dated|historical|nonstandard|obsolete|rare)/).nil?
      keep = keep && (definition =~ /^{{Latn-\w+[^\}]*}}$/).nil?
      keep = keep && (definition =~ /{{rf\w-(?:def|redundant|sense)/).nil?
      keep = keep && (definition =~ /{{rf(?:ex|def)[\|}]/).nil?
      keep = keep && (definition =~ /{{fact[\|\}]/).nil?
      
      if keep
        
        i += 1
        
        # convert wikitext into displayable definition
        display = definition
        
        # fix improperly closed templates
        display = display.gsub(/\{\{[^\}]+\}(?!\})/, '\&}')
        
        # numbered and named template arguments
        display = display.gsub(/\|\s*\d+\s*=\s*/, '|')
        display = display.gsub(/\|\s*from\s*=\s*[^\|\}]+/, '')
        
        # template parameters
        display = display.gsub(/\|\s*(?:ambi|in|un)?(?:countable|formal|transitive)\s*(?=[\|\}])/, '')
        display = display.gsub(/(?<=[\{\|])(chiefly)\|([^\|\}]+)/, '\1 \2')
        
        # simple predictable templates
        display = display.gsub(/{{label\|([^\}]+)}}/, '{{\1}}')
        display = display.gsub(/{{,}}/, ',')
        display = display.gsub(/{{superl}}/, 'superlative')
        display = display.gsub(/{{term\|([^\|\}]+)[^\}]*}}/, '(\1)')
        
        # prefix templates
        display = display.gsub(/^{{(ambi|in|un)?(countable|formal|transitive)[^\}]*}}\s*/, '')
        display = display.gsub(/^\s*or\s+{{(ambi|in|un)?(countable|formal|transitive)[^\}]*}}\s*/, '')
        display = display.gsub(/^{{(?:not )?comparable(\|[^\}]*)*}}\s*/, '')
        display = display.gsub(/^{{([\w ]+)}}/, '(\1)')
        display = display.gsub(/^{{chiefly\|([^\}]+)}}/, '(\1)')
        display = display.gsub(/^{{(\w+)\|_\|(\w+)}}/, '(\1 \2)')
        display = display.gsub(/^{{senseid\|(?:[^\|]+\|)*([^}]+)}}/, '(\1)')
        
        # identifyable templates
        display = display.gsub(/{{([A-Z][^\|\}]+)[^\}]*}}/, '(\1)')
        display = display.gsub(/{{(\w)}}/, '"\1"')
        display = display.gsub(/{{([^\|\}]+ of)\s*\|([^\}]+)}}/, '\1 "\2"')
        display = display.gsub(/{{context(\|(in|un)?(formal|transitive))*}}\s*/, '')
        display = display.gsub(/{{context(?:\|(?:in|un)?(?:formal|transitive))*\|([^}]+)}}/, '(\1)')
        display = display.gsub(/{{(in|un)?(formal|transitive)}}\s*/, '')
        display = display.gsub(/{{(?:context|qualifier|sense)\|(.*?)}}/, '(\1)')
        display = display.gsub(/{{taxlink\|([^\|\}]+)\|([^\}]+)}}/, '\1 \2')
        display = display.gsub(/{{taxlink\|([^\}]+)}}/, '\1')
        display = display.gsub(/{{l(?:\|[^\|\}]+)*\|([^\}\|]+)}}/, '\1')
        display = display.gsub(/{{(?:non-gloss definition|n-g)\|(.*?)}}/, '\1')
        display = display.gsub(/{{(?:gloss|w)\|(.*?)}}/, '\1')
        display = display.gsub(/{{(short for|of a|often|dialect)\s*\|([^\}]+)}}/, '\1 \2')
        display = display.gsub(/{{soplink\|([^\|\}]+)\|([^\|\}]+)}}/, '\1 \2')
        display = display.gsub(/{{etyl\|yi\|[^\}]*}}/, 'Yiddish')
        
        # templates which can be removed wholesale
        display = display.gsub(/{{(?:by extension|defn|defdate|jump|transitive|tritaxon)\|.*?}}\s*/, '')
        
        # any remaining unidentified un-nested templates
        display = display.gsub(/{{([^}]+)}}/) { |match|
          delimiter = ', '
          if !(match =~ /\|_\|/).nil?
            delimiter = ' '
          end
          ret = match
          ret = ret.gsub(/{{([^}]+)}}/, '(\1)')
          ret = ret.gsub(/\|\s*[^=\|\}]+=\s*/, '|')
          ret = ret.gsub(/\|/, delimiter)
          ret
        }
        
        # protect nowiki
        nowiki = []
        display = display.gsub(/<nowiki\/>/, '')
        display = display.gsub(/<nowiki>(.*?)<\/nowiki>/) { |match|
          nowiki.push match.gsub(/<nowiki>(.*?)<\/nowiki>/, '\1')
          '<nowiki>' + nowiki.length.to_s + '</nowiki>'
        }
        
        # known tags
        display = display.gsub(/<ref [^>]+(?:\/>|>.*?<\/ref>)/, '')
        display = display.gsub(/<ref>.*?<\/ref>/, '')
        display = display.gsub(/<ref>.*/, '')
        display = display.gsub(/<(br)(?: [^>]+)?>/, '')
        display = display.gsub(/<math>(.*?)<\/math>/) { |match| 
          match.gsub(/<math>(.*?)<\/math>/, '\1').gsub(/\\/, '')
        }
        display = display.gsub(/<([a-z]\w+)(?: [^>]+)?>(.*?)<\/\1>/, '\2')
        
        # html comments
        display = display.gsub(/<!--.*?-->/, '')
        
        # link syntax
        display = display.gsub(/\[\[([^\]\|]+)\]\]/, '\1')
        display = display.gsub(/\[\[(?:[^\]\|]+\|)+([^\]]+)\]\]/, '\1')
        
        # emphasis
        display = display.gsub(/'''([\w]+)'''/, '"\1"')
        display = display.gsub(/'''([^'].*?)'''/, '\1')
        display = display.gsub(/''(\w+)''/, '\1')
        display = display.gsub(/''(\([^'\)]+\))''/, '\1')
        #display = display.gsub(/('+)([^']+)\1/, '\2')
        
        # punctuation and spacing
        display = display.gsub(/,(?:\s*,)+/, ',')
        display = display.gsub(/\)\(/, ') (')
        display = display.gsub(/\|/, ', ')
        display = display.gsub(/\s+/, ' ')
        display = display.gsub(/^\s+|\s+$/, '')
        display = display.gsub(/[.;:,\s]*$/, '.')
        display = display.gsub(/\.+$/, '.')
        
        # restore nowiki
        display = display.gsub(/<nowiki>(\d+)<\/nowiki>/) { |match|
          nowiki[match.to_i]
        }
        
        # capitalization
        display = display[0].upcase + display[1..-1]
        
        if !(display =~ /(?:<[\w "'=\/]+>|([\[\]\{\}])\1)/).nil?
          buf += "  *****************************************************************\n"
          buf += "  * " + definition + "\n"
          buf += "  * " + display + "\n"
          buf += "  *****************************************************************\n"
        elsif (display =~ /^[\W]*$/).nil?
          buf += display + "\n"
        end
        
        # convert wikitext into speakable script
        script = definition
        script = ''
        
      end
      
    end
    
  }
  return buf
end

# Read input term from command line
start = ARGV[0]
passed_start = start.nil?
n = 0

STDIN.each_line do |line|
  term = line.chomp
  n += 1
  if passed_start or term == start
    passed_start = true
  end
  if passed_start
    definitions = extract_defs(term)
    blob = clean_defs(term, definitions)
    puts "======= " + n.to_s + " - " + term + " ======="
    if !blob.index('*****').nil?
      puts blob
    end
  end
end


################################################################################
exit 1
################################################################################

# Read input term from command line
term = ARGV[0]

# create slides
defs = extract_defs(term)
`mkdir -p terms/#{term}`

slides = []
slides.push({
  'display' => term,
  'script' => term + '.'
})

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


