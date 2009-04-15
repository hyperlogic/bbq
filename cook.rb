#
# cook - generates a binary blob from a .dd file & a .di file
#
#  usage:
#      ruby cook.rb input.di output.bin
#

require 'bbq'

if ARGV[0] && ARGV[1]

  # look up CStruct name
  def Object.const_missing name
    result = $type_registry[name]
    if result
      result
    else
      super name
    end      
  end

  load ARGV[0]

  if $root.nil?
    raise "Missing root in #{ARGV[1]}"
  end

else
  puts "usage:"
  puts "  ruby cook.rb input.di output.bin"
  exit
end

File.open(ARGV[1], "w") do |f|
  str = ""
  $type_registry[$root.type_name].cook(str, $root)
  f.print str
end

