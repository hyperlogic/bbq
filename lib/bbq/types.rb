#
# All types need to be registerd using TypeRegistry.register
# All types are expected to accept the following messages.
#
# define_single field_name       =>  "int foo;"
# define_array field_name, len   =>  "int foo[10];"
# define_ptr field_name          =>  "int* foo;"
# cook chunk, value, name        =>  adds 4 bytes to end of chunk
# alignment                      =>  4 (num bytes, used for alignment)
#
# In addition struct types need to handle the declare method
#
# delcare                       => "struct Foo {
#                                      int32 field1;
#                                      int32* field2;
#                                      int32 feild3[10];
#                                   };"

module TypeRegistry
  @@hash = {}

  # register a new type
  def self.register(sym, instance, file)
    raise "Type #{sym} is already registered!" if @@hash[sym]
    @@hash[sym] = [instance, file]
  end

  # look up a type from a symbol
  def self.lookup_type(sym)
    result = @@hash[sym]
    if result 
      result[0] 
    else 
      nil 
    end
  end

  # look up which file a type was registered from
  def self.lookup_file(sym)
    result = @@hash[sym]
    if result 
      result[1]
    else 
      nil 
    end
  end

  def self.each_type_from(filename)
    @@hash.each do |key, value|
      if value[1] == filename
        yield value[0]
      end
    end
  end
    
end

class BaseType

  @@count = 0

  def initialize type_name, type_alignment, pack_str
    @type_name = type_name
    @type_alignment = type_alignment
    @pack_str = pack_str
  end

  # output the c declaration of one element of this type.
  def define_single field_name
    "#{@type_name} #{field_name};"
  end

  # output the c declaration of an embedded array of this type.
  def define_array field_name, len
    "#{@type_name} #{field_name}[#{len}];"
  end

  # output the c declearation of a pointer to this type.
  def define_ptr field_name
    "#{@type_name}* #{field_name};"
  end

  # append the binary representation of a value of this type onto a chunk.
  # this implementation only works for numeric types
  def cook chunk, value, name
    comment = "(#{@type_name}) #{name}"
    chunk.push([check_num(value, name)].pack(@pack_str), comment)
  end

  # output the alignment requirements for values of this type. (in bytes)
  def alignment
    @type_alignment
  end

  # helper function
  def check_num value, name
    if value.nil?
      0
    else
      raise "value must be Numeric #{name}" unless value.is_a?(Numeric)
      value
    end
  end
end

# single precision float, little-endian byte order
class FloatType < BaseType
  def initialize
    super "float", 4, "e"
  end
end
TypeRegistry.register(:float, FloatType.new, __FILE__)

# boolean
class BoolType < BaseType
  def initialize
    super "unsigned char", 1, nil
  end

  def cook chunk, value, name
    comment = "(#{@type_name}) #{name}"
    # 8 bit unsigned int
    chunk.push([value ? 1 : 0].pack("C"), comment)
  end
end
TypeRegistry.register(:bool, BoolType.new, __FILE__)


# 32 bit unsigned int, little-endian byte order# 
class Uint32Type < BaseType
  def initialize
    super "unsigned int", 4, "I"
  end
end
TypeRegistry.register(:uint32, Uint32Type.new, __FILE__)

# 32 bit signed int, little-endian byte order
class Int32Type < BaseType
  def initialize
    super "int", 4, "i"
  end
end
TypeRegistry.register(:int32, Int32Type.new, __FILE__)

# 16 bit unsigned int
class Uint16Type < BaseType
  def initialize
    super "unsigned short", 2, "S"
  end
end
TypeRegistry.register(:uint16, Uint16Type.new, __FILE__)

# 16 bit signed int
class Int16Type < BaseType
  def initialize
    super "short", 2, "s"
  end
end
TypeRegistry.register(:int16, Int16Type.new, __FILE__)

# 8 bit unsigned int
class Uint8Type < BaseType
  def initialize
    super "unsigned char", 1, "C"
  end
end
TypeRegistry.register(:uint8, Uint8Type.new, __FILE__)

# 8 bit signed int
class Int8Type < BaseType
  def initialize
    super "char", 1, "c"
  end
end
TypeRegistry.register(:int8, Int8Type.new, __FILE__)

# null terminated string
class StringType < BaseType
  def initialize
    super "char*", 4, nil
  end

  def cook chunk, value, name
    comment = "(#{@type_name}) #{name}"
    str_chunk = Chunk.new
    str_chunk.push(value + "\0", "#{name} string")
    chunk.add_pointer str_chunk
  end
end
TypeRegistry.register(:string, StringType.new, __FILE__)
