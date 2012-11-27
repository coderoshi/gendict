#!ruby
# 
# Central location for shared functions among gendict scripts.
# 

BUILD_DIR = './build'
DIST_DIR = './dist'

# Make a given argument safe for inserting into a command-line
def command_arg(arg)
  "'" + arg.gsub(/[\']/, "'\\\\''") + "'"
end

# Generate a build filename for a given slide and suffix
def file_name_gen(slide, suffix)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = "#{BUILD_DIR}/#{term}/#{term}"
  if kind
    file_name += "-#{kind}"
    if index
      file_name += "-#{index}"
    end
  end
  file_name + suffix
end


