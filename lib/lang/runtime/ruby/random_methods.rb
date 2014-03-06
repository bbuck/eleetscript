module EleetScript
  Memory.define_core_methods do
    random = root_namespace["Random"]

    random.class_def :int do |_, arguments, context|
      min, max = 1, 100
      if arguments.length == 1 && arguments.first.is_a?("String", "Number")
        min, max = 0, arguments.first.call(:to_integer).ruby_value
      elsif arguments.length >= 2 && arguments.first.is_a?("String", "Number") && arguments[1].is_a?("String", "Number")
        min, max = arguments.first.call(:to_integer).ruby_value, arguments[1].call(:to_integer).ruby_value
      end
      root_namespace["Integer"].new_with_value(rand(max - min) + min, context.namespace_context)
    end

    random.class_def :float do |_, _, context|
      root_namespace["Float"].new_with_value(rand, context.namespace_context)
    end

    random.class_def :bool do |_, _, context|
      t, f = root_namespace["True"], root_namespace["False"]
      if rand > 0.5
        t
      else
        f
      end
    end

    random.class_def :new do |receiver, arguments, context|
      first_arg = arguments.first
      seed = first_arg.is_a?("String", "Number") ? first_arg.call(:to_integer).ruby_value : nil
      random.new_with_value(Random.new(seed), context.namespace_context)
    end

    random.def :int do |receiver, arguments, context|
      min, max = 1, 100
      if arguments.length == 1 && arguments.first.is_a?("String", "Number")
        min, max = 0, arguments.first.call(:to_integer).ruby_value
      elsif arguments.length >= 2 && arguments.first.is_a?("String", "Number") && arguments[1].is_a?("String", "Number")
        min, max = arguments.first.call(:to_integer).ruby_value, arguments[1].call(:to_integer).ruby_value
      end
      root_namespace["Integer"].new_with_value(receiver.ruby_value.rand(max - min) + min, context.namespace_context)
    end

    random.def :float do |receiver, _, context|
      root_namespace["Float"].new_with_value(receiver.ruby_value.rand, context.namespace_context)
    end

    random.def :bool do |receiver, _, context|
      t, f = root_namespace["True"], root_namespace["False"]
      if receiver.ruby_value.rand > 0.5
        t
      else
        f
      end
    end
  end
end