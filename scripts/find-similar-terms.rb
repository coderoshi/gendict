#!ruby
# 
# Given a term or a set of terms, find related terms by capitalization
# differences.
# 

# read in target terms
if ARGV[0].nil?
  terms = STDIN.read.split("\n")
else
  terms = [ARGV[0]]
end

# read in english words
words = IO.readlines('dumps/english-words.txt')
words_downcase = words.map {|word| word.downcase.chop }

# find words which differ only in capitalization
terms.each do |term|
  term.downcase!
  words.each_with_index do |word, index|
    if words_downcase[index] == term
      puts word
    end
  end
end

