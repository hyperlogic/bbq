class CEnum < BaseType
  def initialize name, hash
    super "enum #{name}", 4, "I"
    @hash = hash

    # HACK: this might not work all the time....
    file = File.basename(caller[2].split(':')[0])

    # keep track of all enums and which file they were defined in
    TypeRegistry.register(name, self, file)

    # index is used to preserve ordering
    @index = @@count
    @@count += 1
  end
  attr_accessor :index

  def cook chunk, value, name
    raise "enum value must be a symbol" unless value.is_a? Symbol
    comment = "(#{@type_name}) name = #{name} value = #{value}"
    num = @hash[value]
    raise "enum value #{value} must be a Fixnum" unless num.is_a? Fixnum
    chunk.push([num].pack(@pack_str), comment)
  end

  def declare
    values = []
    @hash.each {|key, value| values << "#{key} = #{value}"}
    "#{@type_name} {" + values.join(", ") + "};\n"
  end
end
