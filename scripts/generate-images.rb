
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

VPIXELS, HPIXELS = 1280, 720
IMAGE_KIND = 'bmp'

# Extract terms from data dump
def extract_defs(term)
  
  # create shell-safe term
  safe_term = term
  safe_term = safe_term.gsub(/([\-\[\]\{\}\(\)\*\+\?\.\,\\\^\$\|\#])/, '\\\\\\1')
  safe_term = command_arg("^English\\t#{safe_term}\\t")
  
  # extract text definitions from TSV dump file
  data = `grep -P #{safe_term} dumps/enwikt-defs-latest-en.tsv`

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
    base = Magick::Image.read("assets/bg1.png")[0]
    canvas = Magick::ImageList.new
    canvas.new_image(VPIXELS, HPIXELS, Magick::TextureFill.new(base))

    text = Magick::Draw.new
    # text.font_family = 'helvetica'

    # defin

    text.pointsize = 52
    text.gravity = Magick::CenterGravity
    formatted_def = text_break(defin)
    formatted_def = "#{term.upcase}:\n#{formatted_def}"
    text.annotate(canvas, 0,0,0,0, formatted_def) {
      self.fill = 'black'
    }
    canvas.append(true).write("terms/#{term}/#{kind}.#{IMAGE_KIND}")
  end
end

def clean_defs(term, defs)
  slides = []
  defs.each { |kind, definitions|
    
    kind_slides = []
    
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
        #display = display.gsub(/^{{(\w+)\|_\|(\w+)}}/, '(\1 \2)')
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
          ret = ret.gsub(/\|_\|/, '\|')
          ret = ret.gsub(/{{([^}]+)}}/, '(\1)')
          ret = ret.gsub(/\|\s*[^=\|\}]+=\s*/, '|')
          ret = ret.gsub(/\|+/, delimiter)
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
        
        # punctuation and spacing
        display = display.gsub(/,(?:\s*,)+/, ',')
        display = display.gsub(/\)\(/, ') (')
        display = display.gsub(/\|/, ', ')
        display = display.gsub(/,\s*_\s*,/, ' ')
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
        
        #
        #if !(display =~ /(?:<[\w "'=\/]+>|([\[\]\{\}])\1)/).nil?
        #  buf += "  *****************************************************************\n"
        #  buf += "  * " + definition + "\n"
        #  buf += "  * " + display + "\n"
        #  buf += "  *****************************************************************\n"
        #elsif (display =~ /^[\W]*$/).nil?
        #  buf += display + "\n"
        #end
        
        # create readable script (TBD)
        script = display
        script = script.gsub(/^\(([^\)]+)\)\s*/, '\1: ')
        
        kind_slides.push({
          'term' => term,
          'kind' => kind,
          'index' => i,
          'wikitext' => definition,
          'display' => i.to_s + ". " + display,
          'script' => "Definition " + i.to_s + ": " + script
        })
        
      end
      
    end
    
    suffix = " definition"
    if i != 1
      suffix += 's'
    end
    
    slides.push({
      'term' => term,
      'kind' => kind,
      'display' => term + "\n(" + kind + ")",
      'script' => "Part of speech: " + kind + ". " + i.to_s + suffix + "."
    })
    
    slides += kind_slides
    
  }
  return slides
end

def process_all
  
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
  
end

# break text up for image generation
def text_break(str, width)
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

# Generate image
def image_gen(slide)
  
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  body = slide['display'] || nil
  
  # f = Image.new(800,500) { self.background_color = "white" }
  base = Magick::Image.read("assets/bg1.png")[0]
  canvas = Magick::ImageList.new
  canvas.new_image(VPIXELS, HPIXELS, Magick::TextureFill.new(base))

  # heading
  heading = term
  heading_text = Magick::Draw.new
  heading_text.pointsize = 52
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
  #formatted_def = text_break(slide['display'])
  heading_text.annotate(canvas, 0,0,10,0, heading) {
    self.fill = 'black'
  }
  
  # body
  if index
    body_text = Magick::Draw.new
    body_text.pointsize = 48
    body_text.gravity = Magick::NorthWestGravity
    body = text_break(body, 24)
    
    if body.count("\n") > 5
      body = text_break(body, 28)
      body_text.pointsize = 44
    end
    
    #formatted_def = text_break(slide['display'])
    body_text.annotate(canvas, 0,0,20,80, body) {
      self.fill = 'black'
    }
  end
  
  file_name = file_name_gen(slide, ".#{IMAGE_KIND}")
  
  canvas.append(true).write("#{file_name}")
  slide['image'] = file_name
  
end

def command_arg(str)
  "'" + str.gsub(/[\']/, "'\\\\''") + "'"
end

def audio_gen(slide)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = file_name_gen(slide, ".WAV")
  say = command_arg(';;' + slide['script'] + ';;')
  output = command_arg(file_name)
  `say -v Jill #{say} -o #{output}`
  slide['audio'] = file_name
end

def video_gen(slide)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = file_name_gen(slide, ".avi")
  audio = command_arg(slide['audio'])
  image = command_arg(slide['image'])
  video = command_arg(file_name)
  `ffmpeg -loop_input -shortest -y -i #{image} -i #{audio} -acodec libmp3lame -vcodec mpeg4 #{video}`
  slide['video'] = file_name
end

def combine_video(term, slides)
  cmd = 'cat'
  for slide in slides
    cmd += " " + command_arg(slide['video'])
  end
  combined = command_arg("terms/#{term}/#{term}_combined.avi")
  final = command_arg("terms/#{term}.avi")
  cmd += " > #{combined}"
  `#{cmd}`
  `ffmpeg -i #{combined} -r 25 -sameq #{final}`
end

# Read input term from command line
term = ARGV[0]

defs = extract_defs(term)
path = command_arg("terms/#{term}")
`mkdir -p #{path}`

# create slides
slides = []
slides.push({
  'term' => term,
  'display' => term,
  'script' => term + '.'
})

slides += clean_defs(term, defs)

slides.push({
  'term' => term,
  'display' => term,
  'script' => term + '.'
})

#puts slides.to_yaml

for slide in slides
  puts "\n************************************************************************************"
  puts "** " + slide['display'].gsub(/\n/, "\n** ")
  puts "************************************************************************************"
  image_gen(slide)
  audio_gen(slide)
  video_gen(slide)
end

combine_video(term, slides)



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
  'term' => term,
  'display' => term,
  'script' => term + '.'
})

#https://en.wiktionary.org/w/api.php?action=query&prop=imageinfo&titles=File:en-us-{#term}.ogg&iiprop=url&format=json
#{"query":{"pages":{"-1":{"ns":6,"title":"File:en-us-tear-verb.ogg","missing":"","imagerepository":"shared","imageinfo":[{"url":"https:\/\/upload.wikimedia.org\/wikipedia\/commons\/b\/b2\/En-us-tear-verb.ogg","descriptionurl":"https:\/\/commons.wikimedia.org\/wiki\/File:En-us-tear-verb.ogg"}]}}}}

slides.push({
  'term' => term,
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
    # granite = Magick::ImageList.new('granite:')
    base = Magick::Image.read("assets/bg1.png")[0]
    canvas = Magick::ImageList.new
    canvas.new_image(VPIXELS, HPIXELS, Magick::TextureFill.new(granite))
    text = Magick::Draw.new
    # text.font_family = 'helvetica'
    text.pointsize = 52
    text.gravity = Magick::CenterGravity
    formatted_def = text_break(defin)
    formatted_def = "#{term.upcase}:\n#{formatted_def}"
    text.annotate(canvas, 0,0,0,0, formatted_def) {
      self.fill = 'black'
    }
    canvas.append(true).write("terms/#{term}/#{term}-#{kind}-#{i}.#{IMAGE_KIND}")
  end
}

