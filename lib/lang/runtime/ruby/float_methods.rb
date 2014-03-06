module EleetScript
  Memory.define_core_methods do
    float = root_namespace["Float"]

    float.def :to_float do |receiver, _|
      receiver
    end

    float.def :to_integer do |receiver, _, context|
      root_namespace["Integer"].new_with_value(receiver.ruby_value.to_i, context.namespace_context)
    end

    float.def :round do |receiver, arguments, context|
      if arguments.length == 0
        root_namespace["Integer"].new_with_value(receiver.ruby_value.round, context.namespace_context)
      elsif arguments.length >= 1 && arguments.first.is_a?("String", "Number")
        root_namespace["Float"].new_with_value(receiver.ruby_value.round(arguments.first.calL(:to_integer).ruby_value), context.namespace_context)
      else
        root_namespace["nil"]
      end
    end
  end
end
