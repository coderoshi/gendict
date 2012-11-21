# gendict

This project generates videos for dictionary terms.
It does this through a multi-step process.
For any given `term`, the process goes something like this:

* extract definitions for `term` from a wiktionary data dump;
* create a sequence of _slides_ for the term based on the definitions;
* for each slide:
 * generate an image containing the _display_ text of the slide,
 * generate an audio file containing a text-to-speech rendering of the _script_ text of the slide,
 * generate a video file consisting of the still image and audio files mentioned above.
* concatenate the video sequence into one final video.

## Installation and Setup

1. Install ruby
2. Install imagemagick:
 * `brew install imagemagick`
3. Install ffmpeg:
 * `brew install ffmpeg`
4. Install gems:
 * `gem install nokogiri`
 * `C_INCLUDE_PATH=/usr/local/Cellar/imagemagick/6.7.7-6/include/ImageMagick gem install rmagick`
5. `gem install bundler && bundler install`

Additionally you'll need to install any fonts in the `assets/` directory of this project.

* In Finder, navigate to `assets/`
* For each `.ttf` or `.otf` file in this directory:
 * Double-click the file to open it in Font Book
 * Click the Install Font button to install it.

## Grab the latest word list and definitions

gendict uses Wiktionary definitions of terms to generate the videos.
Use these commands to download the latest English Wiktionary definitons.

    cd dumps
    curl -O http://toolserver.org/~enwikt/definitions/enwikt-defs-latest-en.tsv.gz
    curl -O http://dumps.wikimedia.org/enwiktionary/latest/enwiktionary-latest-all-titles-in-ns0.gz
    gunzip *.gz

## Generating slides, images, audio and videos

To generate the slides for a term, use the `make-slides.rb` script:

    ruby scripts/make-slides.rb <term>

This will dump a YAML encoded sequence of slides to standard output.
To see the slides in a more human-readable form, pipe this YAML data into the `print-slides.rb` script:

    ruby scripts/make-slides.rb <term> | ruby scripts/print-slides.rb

To generate the images for the slides for a term, use the `make-images.rb`:

    ruby scripts/make-slides.rb <term> | ruby scripts/make-images.rb

The `make-images.rb` script augments the incoming YAML data, adding a new `image` field to each slide.
It pushes these updated slides as a YAML encoded sequence to standard output.
The images the script generates will be placed in the `terms/<term>` directory.

Similarly, to generate just the audio for a set of slides, use the `make-audio.rb` script.

    ruby scripts/make-slides.rb <term> | ruby scripts/make-audio.rb

Since the image and audio generation scripts both read and write the YAML representation of slides, they can be piped in sequence:

    ruby scripts/make-slides.rb <term> | ruby scripts/make-images.rb | ruby scripts/make-audio.rb

