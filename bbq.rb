# bbq

require 'ostruct'

DEBUG_COOK = false
DEBUG_ALIGN = false

# hook for struct
class Object
  def method_missing sym, *args, &block
    if sym == :struct
      CStruct.new *args, &block
    else
      super
    end
  end
end

class Chunk

  attr_reader :str, :pointers

  Pointer = Struct.new :src_offset, :dest_chunk

  def initialize
    @str = ""
    @pointers = []
  end

  def << str
    @str << str
  end

  def size
    @str.size
  end

  def align alignment
    # insert padding, if necessary
    if @str.size % alignment != 0
      pad = alignment - (@str.size % alignment)
      puts "align #{alignment}, pad = #{pad}" if DEBUG_ALIGN
      pad.times {@str << [0xad].pack("C")}
    end
  end

  def add_pointer dest_chunk
    raise "can only point to chucks" unless dest_chunk.is_a?(Chunk)

    # don't keep track of pointers to empty chunks
    if dest_chunk.size > 0
      @pointers.push Pointer.new(@str.size, dest_chunk)
    end

    # write out a null pointer, it will be fixed up later in resolve_pointers.
    align Uint32Type.alignment
    Uint32Type.cook self, 0
  end

  def resolve_pointers
    new_pointers = []
    @pointers.each do |ptr|

      # resolve any pointers in the dest chunk
      ptr.dest_chunk.resolve_pointers

      # cook the pointer offset into a uint32
      # this offset is the number of bytes from the pointer's location to the desitination.
      temp = Chunk.new
      offset = @str.size - ptr.src_offset
      Uint32Type.cook temp, offset

      # overrite the pointer value in the @str
      @str[ptr.src_offset, temp.size] = temp.str


      # update the global pointer_table
      # TODO: this only works 1 level deep
      # $pointer_table << ptr.src_offset

      # append the pointers from dest_chunk onto new_pointers
      # and offset their src_offsets appropriately
      new_pointers.concat ptr.dest_chunk.pointers.map{|p| Pointer.new p.src_offset + @str.size}

      # now append the dest_chunk on @str
      @str += ptr.dest_chunk.str
    end

    # keep track of the new_pointers
    @pointers.concat new_pointers
  end
end


# All types in the $type_registry are expected to accept the following messages.
#
# define_single field_name       =>  "int foo;"
# define_array field_name, len   =>  "int foo[10];"
# define_ptr field_name          =>  "int* foo;"
# cook chunk, value              =>  adds 4 bytes to end of chunk
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

  def cook chunk, value
    puts "#{@type_name} #{value.inspect}" if DEBUG_COOK
  end

  def alignment
    @type_alignment
  end
end

Float32Type = BaseType.new "float", 4
def Float32Type.cook chunk, value  
  super
  # single precision float, little-endian byte order
  if value.nil?
    chunk << [0].pack("e")
  else
    raise "Value must be Numeric" unless value.is_a?(Numeric)
    chunk << [value].pack("e")
  end
end

BoolType = BaseType.new "bool", 1
def BoolType.cook chunk, value  
  super
  # 8 bit unsigned int
  chunk << [value ? 1 : 0].pack("C")
end

Int32Type = BaseType.new "int", 4
def Int32Type.cook chunk, value
  super
  # 32 bit signed int, little-endian byte order
  if value.nil?
    chunk << [0].pack("i")
  else
    raise "Value must be Numeric" unless value.is_a?(Numeric)
    chunk << [value].pack("i")
  end
end

Uint32Type = BaseType.new "unsigned int", 4
def Uint32Type.cook chunk, value
  raise "Value must be Numeric" unless value.is_a?(Numeric)
  super
   # 32 bit unsigned int, little-endian byte order
   if value.nil?
     chunk << [0].pack("I")
  else
    chunk << [value].pack("I")
  end
end

Uint16Type = BaseType.new "unsigned short", 2
def Uint16Type.cook chunk, value
  super
   # 16 bit unsigned int
   if value.nil?
     chunk << [0].pack("S")
  else
     raise "Value must be Numeric" unless value.is_a?(Numeric)
     chunk << [value].pack("S")
  end
end

Int16Type = BaseType.new "short", 2
def Int16Type.cook chunk, value
  super
   # 16 bit signed int
   if value.nil?
     chunk << [0].pack("s")
  else
     raise "Value must be Numeric" unless value.is_a?(Numeric)
     chunk << [value].pack("s")
  end
end

Uint8Type = BaseType.new "unsigned char", 1
def Uint8Type.cook chunk, value
  super
   # 8 bit unsigned int
   if value.nil?
     chunk << [0].pack("C")
  else
     raise "Value must be Numeric" unless value.is_a?(Numeric)
     chunk << [value].pack("C")
  end
end

Int8Type = BaseType.new "char", 1
def Int8Type.cook chunk, value
  super
   # 8 bit signed int
   if value.nil?
     chunk << [0].pack("c")
  else
     raise "Value must be Numeric" unless value.is_a?(Numeric)
     chunk << [value].pack("c")
  end
end

$type_registry = {:int32 => Int32Type, :uint32 => Uint32Type, 
                  :int16 => Int16Type, :uint16 => Uint16Type, 
                  :int8 => Int8Type, :uint8 => Uint8Type, 
                  :float32 => Float32Type, :bool => BoolType }

class CStruct < BaseType

  attr_accessor :fields, :index

  SingleField = Struct.new :index, :type_name, :field_name, :default_value
  ArrayField = Struct.new :index, :type_name, :field_name, :num_items, :default_value
  VarArrayField = Struct.new :index, :type_name, :field_name, :default_value
  PointerField = Struct.new :index, :type_name, :field_name

  @@count = 0

  def initialize type_name, &block
    @type_name = type_name
    @fields = {}
    instance_eval &block

    # index is used to ensure that structs get defined in the same order in ruby & the generated header
    @index = @@count
    @@count += 1

    # keep track of all structs defined
    $type_registry[@type_name] = self
  end

  def new hash = nil
    # generate a new Struct instance

    # init all fields to default values
    values = {}

    @fields.each do |key, value|
      values[key] = value.default_value
    end

    # set values which override defaults
    if hash
      hash.each do |key, value|
        if @fields[key]
          values[key] = value
        else
          raise "Bad field #{key} in struct #{@type_name}"
        end
      end
    end

    values[:type_name] = @type_name
    OpenStruct.new(values)

  end

  def fixed_array type_name, field_name, num_items, default_value = nil
    # lookup this type in registry
    type = $type_registry[type_name]
    if type
      @fields[field_name] = ArrayField.new(@fields.size, type_name, field_name, num_items, default_value)
    else
      raise "In struct #{@type_name}, Could not make fixed array of #{type_name}"
    end
  end

  def var_array type_name, field_name, default_value = nil
    # lookup this type in registry
    type = $type_registry[type_name]
    if type
      @fields[field_name] = VarArrayField.new(@fields.size, type_name, field_name, default_value)
    else
      raise "In struct #{@type_name}, Could not make var array of #{type_name}"
    end
  end

  def pointer type_name, field_name
    type = $type_registry[type_name]
    if type
      @fields[field_name] = PointerField.new(@fields.size, type_name, field_name)
    else
      raise "In struct #{@type_name}, Could not make pointer to #{type_name}"
    end
  end

  def method_missing symbol, *args
    # lookup this type in registry
    type = $type_registry[symbol]
    if type
      field_name = args[0]
      default_value = args[1]
      @fields[field_name] = SingleField.new(@fields.size, symbol, field_name, default_value)
    else
      super
    end
  end

  def cook chunk, value
    super
    # sort values of members hash by index
    sorted_fields = @fields.values.sort{|a,b| a.index <=> b.index}

    sorted_fields.each do |field|
      type = $type_registry[field.type_name]
      if type
        case field
        when SingleField
          chunk.align type.alignment
          type.cook chunk, value.send(field.field_name)
        when ArrayField
          chunk.align type.alignment
          array = value.send(field.field_name)
          for i in 0...field.num_items
            type.cook chunk, array[i]
          end
        when VarArrayField
          # cook array into dest_chunk
          dest_chunk = Chunk.new
          array = value.send(field.field_name)
          array.each do |elem|
            type.cook dest_chunk, elem  
          end
          # add a pointer
          chunk.add_pointer dest_chunk
          # add the size
          Uint32Type.cook chunk, array.size
        when PointerField
          # TODO: cook chunk pointed to
          #dest_chunk = ...
          #chunk.add_pointer(dest_chunk)
          raise "Don't know how to cook raw pointers yet!"
        else
          raise "Illegal field type!"
        end
      else
        raise "Could not cook #{field.field_name} in struct #{@type_name}"
      end
    end
  end

  def declare
    sorted_fields = @fields.values.sort{|a,b| a.index <=> b.index}

    # define the struct
    lines = ["struct #{@type_name} {"]

    # define each field
    lines += sorted_fields.map do |field|
      type = $type_registry[field.type_name]
      if type
        case field
        when SingleField
          '    ' + type.define_single(field.field_name)
        when ArrayField
          '    ' + type.define_array(field.field_name, field.num_items)
        when VarArrayField
          '    ' + type.define_ptr(field.field_name) + " " + Uint32Type.define_single("#{field.field_name}_size")
        when PointerField
          '    ' + type.define_ptr(field.field_name)
        else
          raise "Illegal field type!"
        end
      else
        raise "Could not find type #{field.type_name} for struct #{@type_name}"
      end
    end

    # close struct
    lines += ["};\n"]

    # return full string
    lines.join "\n"
  end

  def alignment
    # The alignment of the first field.
    field = @fields.values.first{|i| a.index == 0}
    type = $type_registry[field.type_name]
    type.alignment
  end

end
