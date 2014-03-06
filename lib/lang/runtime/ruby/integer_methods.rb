module EleetScript
  Memory.define_core_methods do
    integer = root_namespace["Integer"]

    integer.def :to_float do |receiver, _, context|
      root_namespace["Float"].new_with_value(receiver.ruby_value.to_f, context.namespace_context)
    end

    integer.def :to_integer do |receiver, _, context|
      receiver
    end
  end
end