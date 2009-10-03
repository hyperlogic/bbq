# TODO
# using a $type_registry global is bad form.  Should be a class variable or something.
#
# All types in the $type_registry are expected to accept the following messages.
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

class BaseType

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
    # single precision float, little-endian byte order
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

# boolean
class BoolType < BaseType
  def initialize
    super "bool", 1, nil
  end

  def cook chunk, value, name
    comment = "(#{@type_name}) #{name}"
    # 8 bit unsigned int
    chunk.push([value ? 1 : 0].pack("C"), comment)
  end
end

# 32 bit signed int, little-endian byte order
class Int32Type < BaseType
  def initialize
    super "int", 4, "i"
  end
end

# 32 bit unsigned int, little-endian byte order# 
class Uint32Type < BaseType
  def initialize
    super "unsigned int", 4, "I"
  end
end

# 16 bit unsigned int
class Uint16Type < BaseType
  def initialize
    super "unsigned short", 2, "S"
  end
end

# 16 bit signed int
class Int16Type < BaseType
  def initialize
    super "short", 2, "s"
  end
end

# 8 bit unsigned int
class Uint8Type < BaseType
  def initialize
    super "unsigned char", 1, "C"
  end
end

# 8 bit signed int
class Int8Type < BaseType
  def initialize
    super "char", 1, "c"
  end
end

$type_registry = {:int32 => Int32Type.new, :uint32 => Uint32Type.new, 
                  :int16 => Int16Type.new, :uint16 => Uint16Type.new, 
                  :int8 => Int8Type.new, :uint8 => Uint8Type.new, 
                  :float => FloatType.new, :bool => BoolType.new }
