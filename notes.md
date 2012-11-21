
# notes

Just a place to drop some notes for later.

## Get the images (files) linked from an article

API request:

    https://en.wiktionary.org/w/api.php?action=query&prop=images&titles=#{term}&format=json

Example response:

    {"query":
      {"pages":
        {"5446":{
          "pageid":5446,
          "ns":0,
          "title":"tear",
          "images":[{
            "ns":6,
            "title":"File:Crying-girl.jpg"
          },{
            "ns":6,
            "title":"File:Wikipedia-logo.png"
          },{
            "ns":6,"title":
            "File:en-us-tear-noun.ogg"
          },{
            "ns":6,
            "title":"File:en-us-tear-verb.ogg"
          }]
        }}
      }
    }

## For a given image (file), find out its real URL

API request:

    https://en.wiktionary.org/w/api.php?action=query&prop=imageinfo&titles=File:en-us-#{term}.ogg&iiprop=url&format=json

Example response:

    {"query":
      {"pages":
        {"-1":{
          "ns":6,
          "title":"File:en-us-tear-verb.ogg",
          "missing":"",
          "imagerepository":"shared",
          "imageinfo":[{
            "url":"https:\/\/upload.wikimedia.org\/wikipedia\/commons\/b\/b2\/En-us-tear-verb.ogg",
            "descriptionurl":"https:\/\/commons.wikimedia.org\/wiki\/File:En-us-tear-verb.ogg"
          }]
        }}
      }
    }

