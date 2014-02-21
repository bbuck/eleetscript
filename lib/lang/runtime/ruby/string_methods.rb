module EleetScript
  Memory.define_core_methods do
    string = root_namespace["String"]

    string.def :+ do |receiver, arguments|
      arg = arguments.first
      arg_str = if arg.class?
        arg.name
      elsif arg.instance? && arg.runtime_class.name == "String"
        arg.ruby_value
      else
        arg.call(:to_string).ruby_value
      end
      receiver.ruby_value += arg_str
      receiver
    end

    string.def :is do |receiver, arguments|
      compare_to = arguments.first.ruby_value
      if compare_to == receiver.ruby_value
        root_namespace["true"]
      else
        root_namespace["false"]
      end
    end

    string.def :substr do |receiver, arguments, context|
      if arguments.length < 2
        root_namespace["nil"]
      else
        s, e = arguments
        if s.is_a?("Integer") && e.is_a?("Integer")
          range = if e.ruby_value < 0
            (s.ruby_value..e.ruby_value)
          else
            (s.ruby_value...e.ruby_value)
          end
          root_namespace["String"].new_with_value(receiver.ruby_value[range], context.namespace_context)
        else
          root_namespace["nil"]
        end
      end
    end

    string.def :length do |receiver, arguments, context|
      root_namespace["Integer"].new_with_value(receiver.ruby_value.length, context.namespace_context)
    end

    string.def :upper_case do |receiver, arguments, context|
      string.new_with_value(receiver.ruby_value.upcase, context.namespace_context)
    end

    string.def :lower_case do |receiver, arguments, context|
      string.new_with_value(receiver.ruby_value.downcase, context.namespace_context)
    end

    string.def :[] do |receiver, arguments, context|
      index = arguments.first
      if index.is_a?("Integer")
        index = index.ruby_value
        if index < 0 || index >= receiver.ruby_value.length
          root_namespace.es_nil
        else
          string.new_with_value(receiver.ruby_value[index], context.namespace_context)
        end
      else
        root_namespace.es_nil
      end
    end

    string.def :[]= do |receiver, arguments|
      index, value = arguments
      if index.is_a?("Integer")
        index = index.ruby_value
        if index < 0 && index >= receiver.ruby_value.length
          root_namespace.es_nil
        else
          value_str = value.call(:to_string)
          receiver.ruby_value[index] = value_str.ruby_value
          receiver
        end
      else
        root_namespace.es_nil
      end
    end

    string.def :to_symbol do |receiver, arguments, context|
      root_namespace["Symbol"].new_with_value(receiver.ruby_value.to_sym, context.namespace_context)
    end

    string.def :replace do |receiver, arguments, context|
      if arguments.length < 2
        string.new_with_value(receiver.ruby_value, context.namespace_context)
      else
        pattern, replacement = arguments
        if !pattern.is_a?("Regex")
          pattern = root_namespace["Regex"].call(:new, [pattern.call(:to_string)])
        end
        if replacement.is_a?("Lambda")
          new_str = if pattern.ruby_value.global?
            receiver.ruby_value.gsub(pattern.ruby_value) do
              args = Regexp.last_match[1..-1].map { |match| string.new_with_value(match, context.namespace_context) }
              replacement.call(:call, args).call(:to_string).ruby_value
            end
          else
            receiver.ruby_value.sub(pattern.ruby_value) do
              args = Regexp.last_match[1..-1].map { |match| string.new_with_value(match, context.namespace_context) }
              replacement.call(:call, args).call(:to_string).ruby_value
            end
          end
          string.new_with_value(new_str, context.namespace_context)
        else
          new_str = if pattern.ruby_value.global?
            receiver.ruby_value.gsub(pattern.ruby_value, replacement.call(:to_string).ruby_value)
          else
            receiver.ruby_value.sub(pattern.ruby_value, replacement.call(:to_string).ruby_value)
          end
          string.new_with_value(new_str, context.namespace_context)
        end
      end
    end

    string.def :match do |receiver, arguments, context|
      str_cls, list_cls = root_namespace["String"], root_namespace["List"]
      rx = arguments.first
      args = []
      if rx.is_a?("Regex")
        if rx.ruby_value.global?
          matches = receiver.ruby_value.scan(rx.ruby_value)
          list_args = matches.map do |match|
            args = match.map do |a|
              str_cls.new_with_value(a, context.namespace_context)
            end
            list_cls.call(:new, args)
          end
          list_cls.call(:new, list_args)
        else
          matches = receiver.ruby_value.match(rx.ruby_value)
          if matches.nil?
            list_cls.call(:new)
          else
            args = [str_cls.new_with_value(matches[0], context.namespace_context)]
            if matches.names.length > 0
              args += matches.names.map do |name|
                n, v = str_cls.new_with_value(name, context.namespace_context), str_cls.new_with_value(matches[name], context.namespace_context)
                root_namespace["Pair"].call(:new, [n, v])
              end
            else
              group_matches = matches.to_a
              group_matches.shift # Remove full match
              args += group_matches.map do |res|
                str_cls.new_with_value(res, context.namespace_context)
              end
            end
            list_cls.call(:new, args)
          end
        end
      else
        root_namespace["List"].call(:new)
      end
    end
  end
end