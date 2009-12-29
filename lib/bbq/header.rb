# TODO
# struct hook inside of BBQ.header block should be a method and not use method_missing.

module BBQ

  # insert method_missing & const_missing hooks into class Object
  def BBQ.insert_header_hooks

    # method_messing hook
    Object.send(:define_method, :method_missing) do |sym, *args, &block|
      if sym == :struct
        CStruct.new *args, &block
      elsif sym == :enum
        CEnum.new *args
      elsif args.size == 0
        sym
      else
        super
      end
    end

    # const_missing hook
    meta = class << Object; self; end
    meta.send(:alias_method, :old_const_missing, :const_missing)
    meta.send(:define_method, :const_missing) do |sym|
      sym
    end
  end

  # remove method_missing & const_missing hooks from Object
  def BBQ.remove_header_hooks
    Object.send(:undef_method, :method_missing)
    meta = class << Object; self; end
    meta.send(:alias_method, :const_missing, :old_const_missing)
  end

  def BBQ.header &block
    insert_header_hooks
    block.call
    remove_header_hooks
  end

end
