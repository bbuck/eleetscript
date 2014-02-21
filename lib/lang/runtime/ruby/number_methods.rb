module EleetScript
  Memory.define_core_methods do
    number = root_namespace["Number"]
    int = root_namespace["Integer"]
    float = root_namespace["Float"]

    number.def :+ do |receiver, arguments, context|
      arg = arguments.first
      if arg.is_a?("Number")
        val = receiver.ruby_value + arg.ruby_value
        if val.kind_of?(Fixnum)
          int.new_with_value(val, context.namespace_context)
        else
          float.new_with_value(val, context.namespace_context)
        end
      elsif arg.is_a?("String")
        str = receiver.ruby_value.to_s + arg.ruby_value
        root_namespace["String"].new_with_value(str, context.namespace_context)
      else
        receiver
      end
    end

    number.def :- do |receiver, arguments, context|
      arg = arguments.first
      if arg.is_a?("Number")
        val = receiver.ruby_value - arg.ruby_value
        if val.kind_of?(Fixnum)
          int.new_with_value(val, context.namespace_context)
        else
          float.new_with_value(val, context.namespace_context)
        end
      else
        receiver
      end
    end

    number.def :* do |receiver, arguments, context|
      arg = arguments.first
      if arg.is_a?("Number")
        val = receiver.ruby_value * arg.ruby_value
        if val.kind_of?(Fixnum)
          int.new_with_value(val, context.namespace_context)
        else
          float.new_with_value(val, context.namespace_context)
        end
      else
        receiver
      end
    end

    number.def :/ do |receiver, arguments, context|
      arg = arguments.first
      if arg.is_a?("Number")
        if arg.ruby_value == 0
          int.new_with_value(0, context.namespace_context)
          root_namespace["Errors"].call(:<, [root_namespace["String"].new_with_value("You cannot divide by zero!", context.namespace_context)])
        else
          val = receiver.ruby_value / arg.ruby_value
          if val.kind_of?(Fixnum)
            int.new_with_value(val, context.namespace_context)
          else
            float.new_with_value(val, context.namespace_context)
          end
        end
      else
        receiver
      end
    end

    number.def :% do |receiver, arguments, context|
      arg = arguments.first
      if arg.is_a?("Number")
        if arg.ruby_value == 0
          int.new_with_value(0, context.namespace_context)
          root_namespace["Errors"].call(:<, [root_namespace["String"].new_with_value("You cannot divide by zero!", context.namespace_context)])
        else
          val = receiver.ruby_value % arg.ruby_value
          if val.kind_of?(Fixnum)
            int.new_with_value(val, context.namespace_context)
          else
            float.new_with_value(val, context.namespace_context)
          end
        end
      else
        receiver
      end
    end

    number.def :< do |receiver, arguments|
      arg = arguments.first
      if arg.is_a?("Number")
        if receiver.ruby_value < arg.ruby_value
          root_namespace["true"]
        else
          root_namespace["false"]
        end
      else
        root_namespace["false"]
      end
    end

    number.def :> do |receiver, arguments|
      arg = arguments.first
      if arg.is_a?("Number")
        if receiver.ruby_value > arg.ruby_value
          root_namespace["true"]
        else
          root_namespace["false"]
        end
      else
        root_namespace["false"]
      end
    end

    number.def :is do |receiver, arguments|
      arg = arguments.first
      if arg.is_a?("Number")
        if receiver.ruby_value == arg.ruby_value
          root_namespace["true"]
        else
          root_namespace["false"]
        end
      else
        root_namespace["false"]
      end
    end

    number.def :negate do |receiver, arguments|
      receiver.ruby_value = -receiver.ruby_value
      receiver
    end

    number.def :to_string do |receiver, arguments, context|
      root_namespace["String"].new_with_value(receiver.ruby_value.to_s, context.namespace_context)
    end

    number.def :clone do |receiver, arguments, context|
      if receiver.is_a?("Integer")
        int.new_with_value(receiver.ruby_value, context.namespace_context)
      elsif receiver.is_a?("Float")
        float.new_with_value(receiver.ruby_value, context.namespace_context)
      else
        root_namespace.es_nil
      end
    end
  end
end