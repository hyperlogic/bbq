#
# burn - generates a header from a .dd file
#
#  usage:
#      ruby burn.rb input.dd output.h
#

require 'bbq'

if ARGV[0] && ARGV[1]
  load ARGV[0]
else
  puts "usage:"
  puts "  ruby burn.rb input.dd output.h"
  exit
end

File.open(ARGV[1], "w") do |f|

  # output header guard
  symbol = "#{File.basename(ARGV[1],'.h').upcase}_H"
  f.puts "#ifndef #{symbol}"
  f.puts "#define #{symbol}"
  f.puts ""

  # collect all the structs
  structs = []
  ObjectSpace.each_object CStruct do |struct|
    structs.push struct
  end

  # sort them in the order they were defined in
  structs.sort! {|a,b| a.index <=> b.index}

  # generate each struct declaration
  structs.each do |struct|
    f.print struct.declare
  end

  # close the header guard
  f.puts ""
  f.puts "#endif"

end
