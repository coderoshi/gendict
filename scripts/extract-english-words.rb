#!ruby -n
# extract unique english words from the latest dumps tsv file
# 
# Ex:
#  cat dumps/enwikt-defs-latest-en.tsv | ruby scripts/extract-english-words.rb > dumps/english-words.txt
# 

last = nil

while line = gets
  if !(line =~ /^English\t[a-z][^\s]*\t/).nil?
    term = line.gsub(/^English\t([a-z][^\t]*).*/, '\1')
    if term != last
      puts term
      last = term
    end
  end
end

