#!ruby
# 
# Given a term as input on the command line, extract wiktionary definitions and
# produce a set of 'slides' consisting of de-wikified definitions and title and
# part of speech slides.  Output is pushed to standard output.
# 
# To extract the wiktionary terms, this file uses enwikt-defs-latest-en.tsv,
# which is expected to live in the dumps/ directory.
# 
# TODO:
#  - Use command-line arg flag to allow different dumps/*.tsv file path
#  - Use command-line arg flag to allow output YAML to be pushed to a file
#  - Grab raw wiktionary definitions from a random-access datastore rather than
#    always grepping through the tsv file.
#  - Speed up file search for matching raw definitions
#  - Move common functionality like command_arg() to separate Module

require 'yaml'

require './scripts/common.rb'

# Extract terms from data dump
def extract_defs(term)
  
  # create regex-safe term
  safe_term = term
  safe_term = safe_term.gsub(/([\-\[\]\{\}\(\)\*\+\?\.\,\\\^\$\|\#])/, '\\\\\\1')
  
  # extract text definitions from TSV dump file
  lines = []
  File.open('dumps/enwikt-defs-latest-en.tsv', 'r') {|file|
    file.each_line {|line|
      if !line.match(/^English\t#{safe_term}\t/).nil?
        lines.push(line.split(/\t/, 4).slice(2..-1))
      end
    }
  }

  # extract definitions per part of speech
  defs = lines.inject(Hash.new{[]}) { |result, line|
    part = line[0].downcase
    result[part] = result[part].push(line[1].gsub(/^\s*#\s*/,''))
    result
  }
  
  return defs
  
end

# Turn raw definitions into usable slides
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
        display = display.gsub(/\|\s*(?:or|and)\s*(?=\||\}\})/, '')
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
        display = display.gsub(/\(?\[\[w:[^\]\|]+|Wikipedia\]\]\)?/, '')
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
        display = display.gsub(/&nbsp;/, ' ')
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
        
        # create readable script (TBD)
        script = display
        script = script.gsub(/^\(([^\)]+)\)\s*/, '\1: ')
        
        kind_slides.push({
          'term' => term,
          'kind' => kind,
          'index' => i,
          'wikitext' => definition,
          'display' => i.to_s + ". " + display,
          'script' => "Definition " + i.to_s + ": [[slnc 500]] " + script
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
      'script' => "Part of speech: " + kind + ". [[slnc 500]] " + i.to_s + suffix + "."
    })
    
    slides += kind_slides
    
  }
  return slides
end

# Read input term from command line
term = ARGV[0]

defs = extract_defs(term)

# create slides
slides = []
slides.push({
  'term' => term,
  'display' => term,
  'script' => term + '.'
})

content_slides = clean_defs(term, defs)
slides += content_slides

# displayable definition
definition = content_slides.map{|slide|
  slide['display'].to_s.gsub(/\n/, ' ')
}.compact.join("\n") + "\n\nhttp://en.wiktionary.org/wiki/#{term}"

slides.push({
  'term' => term,
  'display' => term,
  'script' => term + '.'
})

presentation = {
  'term' => term,
  'definition' => definition,
  'slides' => slides
}

puts presentation.to_yaml

