
i = 0

while chunk = gets
  puts chunk.scan(/'[Ee]n-us-.+?\.ogg/)
  i += 1
  if (i>10)
    exit 1
  end
end

