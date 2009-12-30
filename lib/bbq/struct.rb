
class CStruct < BaseType

  attr_accessor :fields, :index

  # NOTE: the index attributre is to preserve ordering when the feilds get added to the @fields hash.
  SingleField = Struct.new :index, :type_name, :field_name, :default_value
  ArrayField = Struct.new :index, :type_name, :field_name, :num_items, :default_value
  VarArrayField = Struct.new :index, :type_name, :field_name, :default_value
  PointerField = Struct.new :index, :type_name, :field_name, :default_value

  def initialize type_name, &block
    @type_name = type_name
    @fields = {}
    instance_eval &block

    # index is used to preserve ordering
    @index = @@count
    @@count += 1

    # HACK: this might not work all the time....
    file = File.basename(caller[2].split(':')[0])

    # keep track of all structs and which file they were defined in
    TypeRegistry.register(@type_name, self, file)
  end

  def define_single field_name
    "struct #{@type_name} #{field_name};"
  end

  # output the c declaration of an embedded array of this type.
  def define_array field_name, len
    "struct #{@type_name} #{field_name}[#{len}];"
  end

  # output the c declearation of a pointer to this type.
  def define_ptr field_name
    "struct #{@type_name}* #{field_name};"
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
    type = TypeRegistry.lookup_type(type_name)
    if type
      @fields[field_name] = ArrayField.new(@fields.size, type_name, field_name, num_items, default_value)
    else
      raise "In struct #{@type_name}, Could not make fixed array of #{type_name}"
    end
  end

  # adds a variable length array into struct, and its associated size feild.
  # memory is outside of struct & pointed to by field i.e. var_array int, my_nums  => int* my_nums;
  def var_array type_name, field_name, default_value = nil
    type = TypeRegistry.lookup_type(type_name)
    if type
      @fields[field_name] = VarArrayField.new(@fields.size, type_name, field_name, default_value)
    else
      raise "In struct #{@type_name}, Could not make var array of #{type_name}"
    end
  end

  # adds a pointer to a chunk of memory.  Useful for embedding raw bytes.
  def pointer type_name, field_name, default_value = nil
    type = TypeRegistry.lookup_type(type_name)
    if type
      @fields[field_name] = PointerField.new(@fields.size, type_name, field_name, default_value)
    else
      raise "In struct #{@type_name}, Could not make pointer to #{type_name}"
    end
  end

  def method_missing symbol, *args
    # lookup this type in registry
    type = TypeRegistry.lookup_type(symbol)
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

  def cook chunk, value, name
    # sort values of members hash by index
    sorted_fields = @fields.values.sort_by{|f| f.index}

    # Sanity check
    if @fields.nil? or sorted_fields.nil?
      raise "Cannot cook struct #{@type_name} with no fields : #{name}"
    end

    sorted_fields.each do |field|
      type = TypeRegistry.lookup_type(field.type_name)
      debug_name = name.to_s + "." + field.field_name.to_s
      if type
        case field
        when SingleField
          chunk.align type.alignment
          if value
            type.cook chunk, value.send(field.field_name), debug_name
          else
            type.cook chunk, nil, debug_name
          end
        when ArrayField
          chunk.align type.alignment
          array = value.send(field.field_name)

          if array.nil?
            raise "fixed_array #{@type_name}.#{field.field_name} is nil! #{name}"
          end

          for i in 0...field.num_items
            type.cook chunk, array[i], debug_name + "[#{i}]"
          end
        when VarArrayField
          # cook array into dest_chunk
          dest_chunk = Chunk.new
          array = value.send(field.field_name)

          if array.nil?
            raise "var_array #{@type_name}.#{field.field_name} is nil! #{name}"
          end

          array.each_with_index do |elem, i|
            type.cook dest_chunk, elem, debug_name + "[#{i}]"
          end
          # add a pointer
          chunk.add_pointer dest_chunk
          # add the size
          TypeRegistry.lookup_type(:uint32).cook chunk, array.size, debug_name + "_size"
        when PointerField
          if value
            dest_chunk = Chunk.new
            dest_chunk.push(value.send(field.field_name), debug_name)
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

    # find the alignment of the largest member
    #
    largest_alignment = 0
    sorted_fields.each do |field|
      type = TypeRegistry.lookup_type(field.type_name)
      debug_name = name.to_s + "." + field.field_name.to_s
      if type
        case field
        when SingleField
          if type.alignment > largest_alignment
            largest_alignment = type.alignment
          end
        when ArrayField
          if type.alignment > largest_alignment
            largest_alignment = type.alignment
          end
        when VarArrayField
          if $LONG_PTRS
            if 8 > largest_alignment
              largest_alignment = 8
            end
          else
            if 4 > largest_alignment
              largest_alignment = 4
            end
          end
        when PointerField

          if $LONG_PTRS
            if 8 > largest_alignment
              largest_alignment = 8
            end
          else
            if 4 > largest_alignment
              largest_alignment = 4
            end
          end
        end
      end
    end

    # finish padding
    chunk.align largest_alignment

  end

  def declare
    sorted_fields = @fields.values.sort_by{|f| f.index}

    # define the struct
    lines = ["struct #{@type_name} {"]

    # define each field
    lines += sorted_fields.map do |field|
      type = TypeRegistry.lookup_type(field.type_name)
      if type
        case field
        when SingleField
          '    ' + type.define_single(field.field_name)
        when ArrayField
          '    ' + type.define_array(field.field_name, field.num_items)
        when VarArrayField
          '    ' + type.define_ptr(field.field_name) + " " + 
            TypeRegistry.lookup_type(:uint32).define_single("#{field.field_name}_size")
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
    type = TypeRegistry.lookup_type(field.type_name)
    type.alignment
  end

end

