# Naming instances of BaseType with a capital letter is bad form (example Int32Type, FloatType)
# using a $type_registry global is bad form.  Should be a class variable or something.

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

  def initialize type_name, type_alignment
    @type_name = type_name
    @type_alignment = type_alignment
  end

  def define_single field_name
    "#{@type_name} #{field_name};"
  end

  def define_array field_name, len
    "#{@type_name} #{field_name}[#{len}];"
  end

  def define_ptr field_name
    "#{@type_name}* #{field_name};"
  end

  def cook chunk, value, name
    puts "#{@type_name} #{value.inspect} #{name}" if DEBUG_COOK
  end

  def alignment
    @type_alignment
  end
end

Float32Type = BaseType.new "float", 4
def Float32Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # single precision float, little-endian byte order
  if value.nil?
    chunk.push([0].pack("e"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("e"), comment)
  end
end

BoolType = BaseType.new "bool", 1
def BoolType.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 8 bit unsigned int
  chunk.push([value ? 1 : 0].pack("C"), comment)
end

Int32Type = BaseType.new "int", 4
def Int32Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 32 bit signed int, little-endian byte order
  if value.nil?
    chunk.push([0].pack("i"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("i"), comment)
  end
end

Uint32Type = BaseType.new "unsigned int", 4
def Uint32Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 32 bit unsigned int, little-endian byte order
  if value.nil?
    chunk.push([0].pack("I"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("I"), comment)
  end
end

Uint16Type = BaseType.new "unsigned short", 2
def Uint16Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 16 bit unsigned int
  if value.nil?
    chunk.push([0].pack("S"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("S"), comment)
  end
end

Int16Type = BaseType.new "short", 2
def Int16Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 16 bit signed int
  if value.nil?
    chunk.push([0].pack("s"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("s"), comment)
  end
end

Uint8Type = BaseType.new "unsigned char", 1
def Uint8Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 8 bit unsigned int
  if value.nil?
    chunk.push([0].pack("C"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("C"), comment)
  end
end

Int8Type = BaseType.new "char", 1
def Int8Type.cook chunk, value, name
  super
  comment = "(#{@type_name}) #{name}"
  # 8 bit signed int
  if value.nil?
    chunk.push([0].pack("c"), comment)
  else
    raise "Value must be Numeric #{name}" unless value.is_a?(Numeric)
    chunk.push([value].pack("c"), comment)
  end
end

$type_registry = {:int32 => Int32Type, :uint32 => Uint32Type, 
                  :int16 => Int16Type, :uint16 => Uint16Type, 
                  :int8 => Int8Type, :uint8 => Uint8Type, 
                  :float => Float32Type, :bool => BoolType }
