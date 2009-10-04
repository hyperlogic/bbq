module BBQ

  # insert const_missing hook into class Object
  def BBQ.insert_data_hooks
    # const_missing hook
    meta = class << Object; self; end
    meta.send(:alias_method, :old_const_missing, :const_missing)
    meta.send(:define_method, :const_missing) do |sym|
      type = $type_registry[sym]
      if type
        type.new
      else
        super
      end
    end
  end

  # remove const_missing hook from Object
  def BBQ.remove_data_hooks
    meta = class << Object; self; end
    meta.send(:alias_method, :const_missing, :old_const_missing)
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
