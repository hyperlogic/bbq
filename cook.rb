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

# see bbq.cpp for pointer table memory layout
class PointerTable
  def initialize
    @ptrs = []
  end

  def << offset
    @ptrs << offset
  end

  def str
    chunk = Chunk.new
    Uint32Type.cook chunk, @ptrs.size
    @ptrs.each do |ptr|
      Uint32Type.cook chunk, ptr
    end
    Uint32Type.cook chunk, @ptrs.size  # output num_pointers again
    chunk.str
  end
end


File.open(ARGV[1], "w") do |f|
  chunk = Chunk.new
  $type_registry[$root.type_name].cook(chunk, $root)
  chunk.resolve_pointers

  # fill up the pointer table
  pointer_table = PointerTable.new
  chunk.pointers.each do |ptr|
    pointer_table << ptr.src_offset
  end

  # output pointer table
  f.print pointer_table.str

  # output main chunk
  f.print chunk.str
end

