module EleetScript
  Memory.define_core_methods do
    regex = root_namespace["Regex"]

    regex.class_def :new do |receiver, arguments|
      pattern, flags = arguments
      pattern = (pattern ? pattern.ruby_value : "")
      flags = (flags ? flags.ruby_value : nil)
      receiver.new_with_value(ESRegex.new(pattern, flags))
    end

    regex.def :pattern do |receiver, arguments|
      root_namespace["String"].new_with_value(receiver.ruby_value.source)
    end

    regex.def :flags do |receiver, arguments|
      root_namespace["String"].new_with_value(receiver.ruby_value.flags)
    end

    regex.def :global= do |receiver, arguments|
      t, f = root_namespace["true"], root_namespace["false"]
      receiver.ruby_value.global = arguments.first == t ? true : false
      receiver
    end

    regex.def :multiline? do |receiver, arguments|
      t, f = root_namespace["true"], root_namespace["false"]
      receiver.ruby_value.multiline? ? t : f
    end

    regex.def :multiline= do |receiver, arguments|
      t, f = root_namespace["true"], root_namespace["false"]
      rx = receiver.ruby_value
      if arguments.first == t
        receiver.ruby_value = ESRegex.new(rx.source, rx.flags + "m")
      else
        receiver.ruby_value = ESRegex.new(rx.source, rx.flags.gsub("m", ""))
      end
      receiver
    end

    regex.def :ignorecase? do |receiver, arguments|
      t, f = root_namespace["true"], root_namespace["false"]
      receiver.ruby_value.ignorecase? ? t : f
    end

    regex.def :ignorecase= do |receiver, arguments|
      t, f = root_namespace["true"], root_namespace["false"]
      rx = receiver.ruby_value
      if arguments.first == t
        receiver.ruby_value = ESRegex.new(rx.source, rx.flags + "i")
      else
        receiver.ruby_value = ESRegex.new(rx.source, rx.flags.gsub("i", ""))
      end
      receiver
    end
  end
end