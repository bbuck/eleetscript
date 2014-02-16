module EleetScript
  Memory.define_core_methods do
    list = root_namespace["List"]

    list.class_def :new do |receiver, arguments|
      new_list = receiver.new_with_value(ListBase.new(root_namespace.es_nil))
      arguments.each do |arg|
        if arg.instance? && arg.runtime_class.name == "Pair"
          new_list.ruby_value.hash_value[arg.call(:key)] = arg.call(:value)
        else
          new_list.ruby_value.array_value << arg
        end
      end
      new_list
    end

    list.def :[] do |receiver, arguments|
      lst = receiver.ruby_value
      arg = arguments.first
      if arg.instance? && arg.runtime_class.name == "Integer"
        index = arg.ruby_value
        if index < lst.array_value.length
          lst.array_value[index]
        else
          lst.hash_value[arg.ruby_value]
        end
      else
        lst.hash_value[arg]
      end
    end

    list.def :[]= do |receiver, arguments|
      lst = receiver.ruby_value
      key = arguments.first
      value = arguments[1]
      if key.instance? && key.runtime_class.name == "Integer"
        index = key.ruby_value
        if index < lst.array_value.length
          lst.array_value[index] = value
        else
          lst.hash_value[key.ruby_value] = value
        end
      else
        lst.hash_value[key] = value
      end
      value
    end

    list.def :merge! do |receiver, arguments|
      lst = receiver.ruby_value
      arg = arguments.first
      if arg.is_a?("List")
        lst.merge!(arg.ruby_value)
      end
      receiver
    end

    list.def :push do |receiver, arguments|
      receiver.ruby_value.array_value << arguments.first
      arguments.first
    end

    list.def :pop do |receiver, arguments|
      val = receiver.ruby_value.array_value.pop
      val.nil? ? root_namespace.es_nil : val
    end

    list.def :shift do |receiver, arguments|
      val = receiver.ruby_value.array_value.shift
      val.nil? ? root_namespace.es_nil : val
    end

    list.def :unshift do |receiver, arguments|
      receiver.ruby_value.array_value.unshift(arguments.first)
      arguments.first
    end

    list.def :keys do |receiver, arguments|
      lst = receiver.ruby_value
      keys = (lst.array_value.length > 0 ? (0...lst.array_value.length).to_a : []).map { |v| root_namespace["Integer"].new_with_value(v) }
      keys.concat(lst.hash_value.keys)
      list.call(:new, keys)
    end

    list.def :values do |receiver, arguments|
      lst = receiver.ruby_value
      vals = (lst.array_value.length > 0 ? lst.array_value.dup : [])
      vals.concat(lst.hash_value.values)
      list.call(:new, vals)
    end

    list.def :delete do |receiver, arguments|
      val = receiver.ruby_value.hash_value.delete(arguments.first)
      val.nil? ? root_namespace.es_nil : val
    end

    list.def :length do |receiver, arguments|
      ruby_val = receiver.ruby_value
      length = ruby_val.array_value.length + ruby_val.hash_value.length
      root_namespace["Integer"].new_with_value(length)
    end

    list.def :first do |receiver, arguments|
      receiver.ruby_value.array_value.first
    end

    list.def :last do |receiver, arguments|
      receiver.ruby_value.array_value.last
    end

    list.def :clear do |receiver, arguments|
      receiver.ruby_value.clear
      receiver
    end

    list.def :join do |receiver, arguments|
      str = if arguments.length > 0
        arguments.first.call(:to_string).ruby_value
      else
        ", "
      end
      values = receiver.call(:values).ruby_value.array_value.map { |v| v.call(:to_string).ruby_value }
      root_namespace["String"].new_with_value(values.join(str))
    end

    list.def :to_string do |receiver, arguments|
      arr_vals = receiver.ruby_value.array_value.map do |val|
        val.call(:inspect).ruby_value
      end
      arr_str = arr_vals.join(", ")
      hash_vals = receiver.ruby_value.hash_value.map do |k, v|
        if k.kind_of?(EleetScriptClassSkeleton)
          k = k.call(:inspect).ruby_value
        else
          k = k.inspect
        end
        "#{k}=>#{v.call(:inspect).ruby_value}"
      end
      hash_str = hash_vals.join(", ")
      str = if arr_str.length > 0 && hash_str.length > 0
        arr_str + ", " + hash_str
      elsif arr_str.length > 0
        arr_str
      elsif hash_str.length > 0
        hash_str
      else
        ""
      end
      root_namespace["String"].new_with_value("[#{str}]")
    end
  end
end