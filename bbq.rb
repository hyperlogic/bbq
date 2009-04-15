# bbq

require 'ostruct'

DEBUG_COOK = true

# All types in the $type_registry are expected to accept the following messages.
#
# define_single field_name       =>  "int foo;"
# define_array field_name, len   =>  "int foo[10];"
# define_ptr field_name          =>  "int* foo;"
# cook value                     =>  4 bytes
#
# In addition struct types need to handle the declare method
#
# delcare                       => "struct Foo {
#                                      int32 field1;
#                                      int32* field2;
#                                      int32 feild3[10];
#                                   };"

class BaseType

  def initialize type_name
    @type_name = type_name
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

  def cook value    
    puts "#{@type_name} #{value.inspect}" if DEBUG_COOK
  end
end

Float32Type = BaseType.new "float"
def Float32Type.cook value  
  super
  raise "Value must be Numeric" unless value.is_a?(Numeric)
  # single precision float, little-endian byte order
  if value.nil?
    [0].pack "e"
  else
    [value].pack "e"
  end
end

Int32Type = BaseType.new "int"
def Int32Type.cook value
  super
  raise "Value must be Numeric" unless value.is_a?(Numeric)
  # 32 bit signed int, little-endian byte order
  if value.nil?
    [0].pack "i"
  else
    [value].pack "i"
  end
end

Uint32Type = BaseType.new "unsigned int"
def Uint32Type.cook value
  raise "Value must be Numeric" unless value.is_a?(Numeric)
  super
  # 32 bit unsigned int, little-endian byte order
  if value.nil?
    [0].pack "I"
  else
    [value].pack "I"
  end
end

$type_registry = {:float32 => Float32Type, :int32 => Int32Type, :uint32 => Uint32Type}

class CStruct < BaseType

  attr_accessor :fields, :index

  SingleField = Struct.new :index, :type_name, :field_name, :default_value
  ArrayField = Struct.new :index, :type_name, :field_name, :num_items, :default_value  
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
      raise "In struct #{@type_name}, Could not make array of #{type_name}"
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

  def cook value
    super
    # sort values of members hash by index
    sorted_fields = @fields.values.sort{|a,b| a.index <=> b.index}

    binary = ""
    sorted_fields.each do |field|
      type = $type_registry[field.type_name]
      if type
        case field
        when SingleField
          binary += type.cook value.send(field.field_name)
        when ArrayField
          for i in 0...field.num_items
            binary += type.cook value.send(field.field_name)[i]
          end
        when PointerField
          # TODO:
          raise "Don't know how to cook pointers yet!"
        else
          raise "Illegal field type!"
        end
      else
        raise "Could not cook #{field.field_name} in struct #{@type_name}"
      end
    end
    binary
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
          "    " + type.define_single(field.field_name)
        when ArrayField
          "    " + type.define_array(field.field_name, field.num_items)
        when PointerField
          "    " + type.define_ptr(field.field_name)
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

end
