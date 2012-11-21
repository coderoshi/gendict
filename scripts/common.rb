#!ruby
# 
# Central location for shared functions among gendict scripts.
# 

# Make a given argument safe for inserting into a command-line
def command_arg(arg)
  "'" + arg.gsub(/[\']/, "'\\\\''") + "'"
end

# Generate a filename for a given slide and suffix
def file_name_gen(slide, suffix)
  term = slide['term']
  kind = slide['kind'] || nil
  index = slide['index'] || nil
  file_name = "terms/#{term}/#{term}"
  if kind
    file_name += "-#{kind}"
    if index
      file_name += "-#{index}"
    end
  end
  file_name + suffix
end


