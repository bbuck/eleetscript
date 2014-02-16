module EleetScript
  Memory.define_core_methods do
    io = root_namespace["IO"]

    io.class_def :print do |receiver, arguments|
      print arguments.first.call(:to_string).ruby_value
      root_namespace.es_nil
    end

    io.class_def :println do |receiver, arguments|
      puts arguments.first.call(:to_string).ruby_value
      root_namespace.es_nil
    end

    io.class_def :new do |receiver, arguments|
      io
    end
  end
end