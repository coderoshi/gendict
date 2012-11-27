#!ruby

require 'set'
require './scripts/common.rb'

raise "YOUTUBE_UN required" unless ENV['YOUTUBE_UN']
raise "YOUTUBE_PW required" unless ENV['YOUTUBE_PW']
raise "YOUTUBE_DK required" unless ENV['YOUTUBE_DK']

stop_words = Set.new(File.read('dumps/stop-words.txt').split("\n"))

terms = File.read('dumps/common-english-words.txt').split("\n").sort


# a range of words
first, last = ARGV[0], ARGV[1]

running = first.nil?
for term in terms
  term.downcase!
  running ||= term == first
  next unless running
  next if stop_words.include?(term)
  term_arg = command_arg(term)
  `ruby scripts/gendict.rb #{term_arg}`
  running = false if term == last
end
