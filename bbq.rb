# bbq

class BasicType

  attr_accessor :name, :default, :c_type

  def burn
    "#{@c_type} #{@name};"
  end
end

class Float32 < BasicType

  def initialize name, default = nil
    @name = name
    @default = default
    @c_type = "float"
  end

  def cook value
    # single precision float, little-endian byte order
    if value.nil?
      [0].pack "e"
    else
      [value].pack "e"
    end
  end

end

class Int32 < BasicType

  def initialize name, default = nil
    @name = name
    @default = default
    @c_type = "int"
  end

  def cook value
    # 32 bit signed int, little-endian byte order
    if value.nil?
      [0].pack "i"
    else
      [value].pack "i"
    end
  end

end

class Uint32 < BasicType

  def initialize name, default
    @name = name
    @default = default
    @c_type = "unsigned int"
  end

  def cook value
    # 32 bit unsigned int, little-endian byte order
    if value.nil?
      [0].pack "I"
    else
      [value].pack "I"
    end
  end

end

class Instance

  attr_accessor :members

  def initialize struct, hash
    @struct = struct

    # init all members to default values
    @members = {}
    @struct.members.each do |key,value|
      @members[key] = value.type.default
    end

    # set values which override defaults
    hash.each do |key,value|
      @members[key] = value
    end
  end

  def cook
    binary = ""
    @members.each do |key,value|
      type = @struct.members[key].type
      binary += type.cook value
    end
    binary
  end
end


class Structure

  Member = Struct.new :type, :index

  attr_accessor :members, :name

  def initialize name, &block
    @name = name
    @members = {}
    @count = 0
    instance_eval &block
  end

  def new hash
    Instance.new self, hash
  end

  def float32 name, default
    @members[name] = Member.new Float32.new(name, default), @count
    @count += 1
  end

  def int32 name, default
    @members[name] = Member.new Int32.new(name, default), @count
    @count += 1
  end

  def uint32 name, default
    @members[name] = Member.new Uint32.new(name, default), @count
    @count += 1
  end

  def burn
    # sort values of members hash by index
    sorted_members = @members.values.sort{|a,b| a.index <=> b.index}

    # burn each member type
    lines = ["struct #{@name} {"]
    lines += sorted_members.map{|m| "    " + m.type.burn}
    lines += ["};\n"]
    lines.join "\n"
  end
end


# example .dd file
Polar = Structure.new :Polar do
  float32 :radius, 0
  float32 :theta, 0  
  int32 :poo, 10
end

# generate header file
print Polar.burn

# example .di file
ten = Polar.new :radius => 10, :theta=> (1/2)

#p Polar.members
#p ten.members

# generate binary file
print ten.cook

