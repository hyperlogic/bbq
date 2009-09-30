# bbq

# TODO
# Naming instances of BaseType with a capital letter is bad form (example Int32Type, FloatType)
# using a $type_registry global is bad form.  Should be a class variable or something.
# struct hook inside of BBQ.header block should be a method and not use method_missing.

DEBUG_COOK = false
DEBUG_ALIGN = false

require 'ostruct'

class OpenStruct
  def build hash
    hash.each do |key, value|
      self.send("#{key}=", value)
    end
    self
  end
end

module BBQ

  # insert method_missing & const_missing hooks into class Object
  def BBQ.insert_header_hooks

    # method_messing hook
    Object.send(:define_method, :method_missing) do |sym, *args, &block|
      BBQ.header_method_missing sym, *args, &block
    end

    # const_missing hook
    meta = class << Object; self; end
    meta.send(:alias_method, :old_const_missing, :const_missing)
    meta.send(:define_method, :const_missing) do |sym|
      BBQ.header_const_missing sym
    end
  end

  # remove method_missing & const_missing hooks from Object
  def BBQ.remove_header_hooks
    Object.send(:undef_method, :method_missing)
    meta = class << Object; self; end
    meta.send(:alias_method, :const_missing, :old_const_missing)
  end

  def BBQ.header_method_missing sym, *args, &block
    if sym == :struct
      CStruct.new *args, &block
    elsif args.size == 0
      sym
    else
      super
    end
  end  

  def BBQ.header_const_missing sym
    sym
  end

  def BBQ.header &block
    insert_header_hooks
    block.call
    remove_header_hooks
  end

  # insert method_missing & const_missing hooks into class Object
  def BBQ.insert_data_hooks

    # method_messing hook
    Object.send(:define_method, :method_missing) do |sym, *args, &block|
      BBQ.data_method_missing sym, *args, &block
    end

    # const_missing hook
    meta = class << Object; self; end
    meta.send(:alias_method, :old_const_missing, :const_missing)
    meta.send(:define_method, :const_missing) do |sym|
      BBQ.data_const_missing sym
    end
  end

  # remove method_missing & const_missing hooks from Object
  def BBQ.remove_data_hooks
    Object.send(:undef_method, :method_missing)
    meta = class << Object; self; end
    meta.send(:alias_method, :const_missing, :old_const_missing)
  end

  def BBQ.data_method_missing sym, *args, &block
    super
  end

  def BBQ.data_const_missing sym
    type = $type_registry[sym]
    if type
      type.new
    else
      super
    end
  end

  def BBQ.data &block
    insert_data_hooks
    @root = block.call
    remove_data_hooks
  end

  def BBQ.data_root
    @root
  end
end

# Represents a binary chunk of data
# binary data is pushed with the << operator
# pointers to other Chunks can be added with the add_pointer method
class Chunk

  attr_reader :str, :pointers

  Pointer = Struct.new :src_offset, :dest_chunk

  def initialize str = nil
    if str
      @str = str
    else
      @str = ""
    end
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

      # align the chunk, so the thing pointed to will be 4 byte aligned.
      # TODO: I should really keep track of the pointed to chunk's alignment requirements...
      align 4      

      # resolve any pointers in the dest chunk
      ptr.dest_chunk.resolve_pointers

      # cook the pointer offset into a uint32
      # this offset is the number of bytes from the pointer's location to the destination.
      temp = Chunk.new
      offset = @str.size - ptr.src_offset
      Uint32Type.cook temp, offset

      # overrite the pointer value in the @str
      @str[ptr.src_offset, temp.size] = temp.str

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
  super
  # 32 bit unsigned int, little-endian byte order
  if value.nil?
     chunk << [0].pack("I")
   else
     raise "Value must be Numeric" unless value.is_a?(Numeric)
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

  # NOTE: the index attributre is to preserve ordering when the feilds get added to the @fields hash.
  SingleField = Struct.new :index, :type_name, :field_name, :default_value
  ArrayField = Struct.new :index, :type_name, :field_name, :num_items, :default_value
  VarArrayField = Struct.new :index, :type_name, :field_name, :default_value
  PointerField = Struct.new :index, :type_name, :field_name, :default_value
  StringField = Struct.new :index, :type_name, :field_name, :default_value

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
    # generate a new OpenStruct instance

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

  # adds a new fixed size array into struct.
  # memory is embeded into struct. i.e. fixed_array int, my_nums, 3  => int my_nums[3];
  def fixed_array type_name, field_name, num_items, default_value = nil
    # lookup this type in registry
    type = $type_registry[type_name]
    if type
      @fields[field_name] = ArrayField.new(@fields.size, type_name, field_name, num_items, default_value)
    else
      raise "In struct #{@type_name}, Could not make fixed array of #{type_name}"
    end
  end

  # adds a variable length array into struct, and its associated size feild.
  # memory is outside of struct & pointed to by field i.e. var_array int, my_nums  => int* my_nums;
  def var_array type_name, field_name, default_value = nil
    # lookup this type in registry
    type = $type_registry[type_name]
    if type
      @fields[field_name] = VarArrayField.new(@fields.size, type_name, field_name, default_value)
    else
      raise "In struct #{@type_name}, Could not make var array of #{type_name}"
    end
  end

  # adds string, which will become a field of type char*.
  def string field_name, default_value = nil
    @fields[field_name] = StringField.new(@fields.size, :uint8, field_name, default_value)
  end

  # adds a pointer to a chunk of memory.  Useful for embedding raw bytes.
  def pointer type_name, field_name, default_value = nil
    type = $type_registry[type_name]
    if type
      @fields[field_name] = PointerField.new(@fields.size, type_name, field_name, default_value)
    else
      raise "In struct #{@type_name}, Could not make pointer to #{type_name}"
    end
  end

  def method_missing symbol, *args
    # lookup this type in registry
    type = $type_registry[symbol]
    if type
      if args.size > 0
        field_name = args[0]
        default_value = args[1]
        @fields[field_name] = SingleField.new(@fields.size, symbol, field_name, default_value)
      else
        symbol
      end
    else
      super
    end
  end

  def cook chunk, value
    super

    # sort values of members hash by index
    sorted_fields = @fields.values.sort_by{|f| f.index}

    sorted_fields.each do |field|
      type = $type_registry[field.type_name]
      if type
        case field
        when SingleField
          chunk.align type.alignment
          if value
            type.cook chunk, value.send(field.field_name)
          else
            type.cook chunk, nil
          end
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
        when StringField
          # cook string
          dest_chunk = Chunk.new
          string = value.send(field.field_name)
          if string.is_a? String
            dest_chunk << string + "\0"
          else
            raise "#{field.field_name} must be a String not a #{string.class}"
          end
          # add a pointer
          chunk.add_pointer dest_chunk
        when PointerField
          if value
            dest_chunk = Chunk.new value.send(field.field_name)
          else
            dest_chunk = Chunk.new
          end

          # add a pointer
          chunk.add_pointer dest_chunk          
        else
          raise "Illegal field type!"
        end
      else
        raise "Could not cook #{field.field_name} in struct #{@type_name}"
      end
    end
  end

  def declare
    sorted_fields = @fields.values.sort_by{|f| f.index}

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
        when StringField
          '    ' + Int8Type.define_ptr(field.field_name)
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

