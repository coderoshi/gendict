require 'youtube_it'

YOUTUBE_UN = ENV['YOUTUBE_UN'] || "viddictionary"
YOUTUBE_PW = ENV['YOUTUBE_PW']
YOUTUBE_DK = ENV['YOUTUBE_DK']

client = YouTubeIt::Client.new(
  :username => YOUTUBE_UN,
  :password =>  YOUTUBE_PW,
  :dev_key => YOUTUBE_DK)

def build_definition(slides, term)
  definition = slides.map{|slide|
    term == slide['display'] ? nil : slide['display'].to_s.gsub(/\n/, ' ')
  }.compact.join("\n")
  url = "http://en.wiktionary.org/wiki/#{term}"
  definition += "\n\n" + url
end

def upload_video(client, slides)
  term = slides.first['term']
  definition = build_definition(slides, term)
  client.video_upload(
    File.open("terms/#{term}.avi"),
    :title => term,
    :description => definition,
    :keywords => [term, 'definition'])

end

presentation = YAML::load(STDIN.read)
upload_video(client, presentation['slides'])
