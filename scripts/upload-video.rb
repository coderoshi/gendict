#!ruby
# 
# Takes a presentation serialized as YAML from STDIN for which a video has
# already been generated and uploads it to YouTube.
# 

require 'yaml'
require 'youtube_it'

require './scripts/common.rb'

# builds out a definiton for a given term, if not already specified in the
# presentation
def build_definition(presentation)
  slides = presentation['slides']
  term = presentation['term']
  definition = presentation['definition']
  if definition.nil?
    definition = slides.map{|slide|
      term == slide['display'] ? nil : slide['display'].to_s.gsub(/\n/, ' ')
    }.compact.join("\n")
    url = "http://en.wiktionary.org/wiki/#{term}"
    definition += "\n\n" + url
  end
  return definition
end

# upload a video given a client connection and a presentation data object
def upload_video(client, presentation)
  slides = presentation['slides']
  term = presentation['term']
  definition = build_definition(presentation)
  client.video_upload(
    File.open(presentation['video']),
    :title => term,
    :description => definition,
    :keywords => [term, 'definition'])

end

client = YouTubeIt::Client.new(
  :username => ENV['YOUTUBE_UN'],
  :password => ENV['YOUTUBE_PW'],
  :dev_key => ENV['YOUTUBE_DK'])

presentation = YAML::load(STDIN.read)
upload_video(client, presentation)

