# Represents a binary chunk of data
# binary data is appended to end of chunk via the push method
# pointers to other Chunks can be added with the add_pointer method
class Chunk

  attr_reader :str, :pointers, :comments

  Pointer = Struct.new :src_offset, :dest_chunk

  def initialize
    @str = ""
    @pointers = []
    @comments = []
  end

  def push str, comment
    @comments << [@str.size, comment]
    @str << str
  end

  def size
    @str.size
  end

  def pad start, alignment
    if start % alignment != 0
      alignment - (start % alignment)
    else
      0
    end
  end

  def align alignment
    # insert padding, if necessary
    pad(@str.size, alignment).times do 
      @str << [0xad].pack("C")
    end
  end

  def add_pointer dest_chunk
    raise "can only point to chucks" unless dest_chunk.is_a?(Chunk)

    # don't keep track of pointers to empty chunks
    if dest_chunk.size > 0
      padding = pad(@str.size, $LONG_PTRS ? 8 : 4)
      @pointers.push Pointer.new(@str.size + padding, dest_chunk)
    end

    # write out a null pointer, it will be fixed up later in resolve_pointers.
    if $LONG_PTRS
      align TypeRegistry.lookup_type(:uint64).alignment
      TypeRegistry.lookup_type(:uint64).cook self, 0, "pointer 64bit"
    else
      align TypeRegistry.lookup_type(:uint32).alignment
      TypeRegistry.lookup_type(:uint32).cook self, 0, "pointer 32bit"
    end
  end

  def resolve_pointers
    new_pointers = []
    @pointers.each do |ptr|

      # align the chunk, so the thing pointed to will be 4 byte aligned.
      # TODO: I should really keep track of the pointed to chunk's alignment requirements...
      align 8

      # resolve any pointers in the dest chunk
      ptr.dest_chunk.resolve_pointers

      # cook the pointer offset into a uint32 or uint64
      # this offset is the number of bytes from the pointer's location to the destination.
      temp = Chunk.new
      offset = @str.size - ptr.src_offset

      if $LONG_PTRS
        TypeRegistry.lookup_type(:uint64).cook(temp, offset, "offset")
      else
        TypeRegistry.lookup_type(:uint32).cook(temp, offset, "offset")
      end

      # overrite the pointer value in the @str
      @str[ptr.src_offset, temp.size] = temp.str

      # append the pointers from dest_chunk onto new_pointers
      # and offset their src_offsets appropriately
      new_pointers.concat ptr.dest_chunk.pointers.map{|p| Pointer.new p.src_offset + @str.size}

      # now append the dest_chunk on @str
      orig_size = @str.size
      @str += ptr.dest_chunk.str

      # append the comments as well
      ptr.dest_chunk.comments.each do |comment|
        @comments << [comment[0] + orig_size, comment[1]]
      end
    end

    # keep track of the new_pointers
    @pointers.concat new_pointers
  end
end
