## Install

1. Install ruby
2. Install imagemagick: `brew install imagemagick`
3. Install ffmpeg: `brew install ffmpeg`
4. Install gems:
 * `gem install nokogiri`
 * `C_INCLUDE_PATH=/usr/local/Cellar/imagemagick/6.7.7-6/include/ImageMagick gem install rmagick`
5. `gem install bundler && bundler install`

## Run

`ruby gen.rb [TERM]`

## Output

Generated term files are under the terms directory.

