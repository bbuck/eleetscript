require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "lang/runtime/array"
require "lang/runtime/base_classes"

module EleetScript
  class Memory
    attr_reader :root, :root_context, :root_namespace

    ROOT_OBJECTS = {
      "Object" => nil,
      "Number" => nil,
      "Integer" => "Number",
      "Float" => "Number",
      "Enumerable" => nil,
      "List" => "Enumerable",
      "String" => "Enumerable",
      "Regex" => nil,
      "IO" => nil,
      "Lambda" => nil,
      "TrueClass" => nil,
      "FalseClass" => nil,
      "NilClass" => nil
    }

    def initialize
      @root_namespace = NamespaceContext.new(nil, nil)
      @root_path = File.join(File.dirname(__FILE__), "eleetscript")
    end

    def bootstrap(loader)
      return if @bootstrapped
      @bootstrapped = true

      ROOT_OBJECTS.each do |obj_name, parent_class|
        if parent_class.nil?
          @root_namespace[obj_name] = EleetScriptClass.create(@root_namespace, obj_name)
        else
          @root_namespace[obj_name] = EleetScriptClass.create(@root_namespace, obj_name, @root_namespace[parent_class])
        end
      end

      @root = @root_namespace["Object"].new
      @root_namespace.current_self = @root
      @root_namespace.current_class = @root.runtime_class

      @root_namespace["true"] = @root_namespace["TrueClass"].new_with_value(true)
      @root_namespace["false"] = @root_namespace["FalseClass"].new_with_value(false)
      @root_namespace["nil"] = @root_namespace["NilClass"].new_with_value(nil)

      # Global Errors Object
      @root_namespace["Errors"] = @root_namespace["List"].new_with_value(ListBase.new(@root_namespace.es_nil))

      load_object_methods
      load_io_methods
      load_string_methods
      load_regex_methods
      load_number_methods
      load_boolean_methods
      load_nil_methods
      load_list_methods
      load_lambda_methods

      files = Dir.glob(File.join(@root_path, "**", "*.es"))
      files.each do |file|
        loader.load(file)
      end
    end

    private

    def load_object_methods
      object = @root_namespace["Object"]

      object.class_def :new do |receiver, arguments|
        ins = receiver.new
        ins.call("init", arguments)
        ins
      end

      object.def :kind_of? do |receiver, arguments|
        t, f = @root_namespace["true"], @root_namespace["false"]
        if arguments.length == 0 || !arguments.first.class?
          f
        else
          names = []
          names << receiver.runtime_class.name
          cur_class = receiver.runtime_class
          while @root_namespace["Object"] != cur_class.super_class
            names << cur_class.super_class.name
            cur_class = cur_class.super_class
          end
          names << "Object" # Base of everything
          name = arguments.first.name
          names.include?(name) ? t : f
        end
      end

      object.def :class do |receiver, arguments|
        receiver.runtime_class
      end

      object.def :class_name do |receiver, arguments|
        @root_namespace["String"].new_with_value(receiver.runtime_class.name)
      end

      object.class_def :class_name do |receiver, arguments|
        @root_namespace["String"].new_with_value(receiver.name)
      end

      object.def :is do |receiver, arguments|
        if receiver == arguments.first
          @root_namespace["true"]
        else
          @root_namespace["false"]
        end
      end

      object.def :clone do |receiver, arguments|
        cls_name = receiver.runtime_class.name
        if ["Integer", "Float", "String", "List"].include?(cls_name)
          receiver.runtime_class.new_with_value(receiver.ruby_value.dup)
        else
          ins = receiver.runtime_class.call(:new)
          ins.ruby_value = receiver.ruby_value.dup
        end
      end
    end

    def load_io_methods
      io = @root_namespace["IO"]

      io.class_def :print do |receiver, arguments|
        print arguments.first.call(:to_string).ruby_value
        @root_namespace.es_nil
      end

      io.class_def :println do |receiver, arguments|
        puts arguments.first.call(:to_string).ruby_value
        @root_namespace.es_nil
      end

      io.class_def :new do |receiver, arguments|
        io
      end
    end

    def load_string_methods
      string = @root_namespace["String"]

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
          @root_namespace["true"]
        else
          @root_namespace["false"]
        end
      end

      string.def :substr do |receiver, arguments|
        if arguments.length < 2
          @root_namespace["nil"]
        else
          s, e = arguments
          if s.is_a?("Integer") && e.is_a?("Integer")
            range = if e.ruby_value < 0
              (s.ruby_value..e.ruby_value)
            else
              (s.ruby_value...e.ruby_value)
            end
            @root_namespace["String"].new_with_value(receiver.ruby_value[range])
          else
            @root_namespace["nil"]
          end
        end
      end

      string.def :length do |receiver, arguments|
        @root_namespace["Integer"].new_with_value(receiver.ruby_value.length)
      end

      string.def :upper_case do |receiver, arguments|
        string.new_with_value(receiver.ruby_value.upcase)
      end

      string.def :lower_case do |receiver, arguments|
        string.new_with_value(receiver.ruby_value.downcase)
      end

      string.def :[] do |receiver, arguments|
        index = arguments.first
        if index.is_a?("Integer")
          index = index.ruby_value
          if index < 0 || index >= receiver.ruby_value.length
            @root_namespace.es_nil
          else
            string.new_with_value(receiver.ruby_value[index])
          end
        else
          @root_namespace.es_nil
        end
      end

      string.def :[]= do |receiver, arguments|
        index, value = arguments
        if index.is_a?("Integer")
          index = index.ruby_value
          if index < 0 && index >= receiver.ruby_value.length
            @root_namespace.es_nil
          else
            value_str = value.call(:to_string)
            receiver.ruby_value[index] = value_str.ruby_value
            receiver
          end
        else
          @root_namespace.es_nil
        end
      end

      string.def :replace do |receiver, arguments|
        if arguments.length < 2
          string.new_with_value(receiver.ruby_value)
        else
          pattern, replacement = arguments
          if !pattern.is_a?("Regex")
            pattern = @root_namespace["Regex"].call(:new, [pattern.call(:to_string)])
          end
          if replacement.is_a?("Lambda")
            new_str = if pattern.ruby_value.global?
              receiver.ruby_value.gsub(pattern.ruby_value) do |*args|
                args = args.map { |arg| string.new_with_value(arg) }
                replacement.call(:call, args).call(:to_string).ruby_value
              end
            else
              receiver.ruby_value.sub(pattern.ruby_value) do |*args|
                args = args.map { |arg| string.new_with_value(arg) }
                replacement.call(:call, args).call(:to_string).ruby_value
              end
            end
          else
            new_str = if pattern.ruby_value.global?
              receiver.ruby_value.gsub(pattern.ruby_value, replacement.call(:to_string).ruby_value)
            else
              receiver.ruby_value.sub(pattern.ruby_value, replacement.call(:to_string).ruby_value)
            end
            string.new_with_value(new_str)
          end
        end
      end

      string.def :match do |receiver, arguments|
        str_cls, list_cls = @root_namespace["String"], @root_namespace["List"]
        rx = arguments.first
        if rx.is_a?("Regex")
          if rx.ruby_value.global?
            matches = receiver.ruby_value.scan(rx.ruby_value)
            list_args = matches.map do |match|
              args = match.map do |a|
                str_cls.new_with_value(a)
              end
              list_cls.call(:new, args)
            end
            list_cls.call(:new, args)
          else
            matches = receiver.ruby_value.match(rx.ruby_value)
            if matches.nil?
              list_cls.call(:new)
            else
              args = [str_cls.new_with_value(matches[0])]
              if matches.names.length > 0
                args += matches.names.map do |name|
                  n, v = str_cls.new_with_value(name), str_cls.new_with_value(matches[name])
                  @root_namespace["Pair"].call(:new, [n, v])
                end
              else
                group_matches = matches.to_a
                group_matches.shift # Remove full match
                args += group_matches.map do |res|
                  str_cls.new_with_value(res)
                end
              end
              list_cls.call(:new, args)
            end
          end
        else
          @root_namespace["List"].call(:new)
        end
      end
    end

    def load_number_methods
      number = @root_namespace["Number"]
      int = @root_namespace["Integer"]
      float = @root_namespace["Float"]

      number.def :+ do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          val = receiver.ruby_value + arg.ruby_value
          if val.kind_of?(Fixnum)
            int.new_with_value(val)
          else
            float.new_with_value(val)
          end
        elsif arg.is_a?("String")
          str = receiver.ruby_value.to_s + arg.ruby_value
          @root_namespace["String"].new_with_value(str)
        else
          receiver
        end
      end

      number.def :- do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          val = receiver.ruby_value - arg.ruby_value
          if val.kind_of?(Fixnum)
            int.new_with_value(val)
          else
            float.new_with_value(float)
          end
        else
          receiver
        end
      end

      number.def :* do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          val = receiver.ruby_value * arg.ruby_value
          if val.kind_of?(Fixnum)
            int.new_with_value(val)
          else
            float.new_with_value(float)
          end
        else
          receiver
        end
      end

      number.def :/ do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if arg.ruby_value == 0
            int.new_with_value(0)
          else
            val = receiver.ruby_value / arg.ruby_value
            if val.kind_of?(Fixnum)
              int.new_with_value(val)
            else
              float.new_with_value(float)
            end
          end
        else
          receiver
        end
      end

      number.def :% do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if arg.ruby_value == 0
            int.new_with_value(0)
          else
            val = receiver.ruby_value % arg.ruby_value
            if val.kind_of?(Fixnum)
              int.new_with_value(val)
            else
              float.new_with_value(float)
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
            @root_namespace["true"]
          else
            @root_namespace["false"]
          end
        else
          @root_namespace["false"]
        end
      end

      number.def :> do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if receiver.ruby_value > arg.ruby_value
            @root_namespace["true"]
          else
            @root_namespace["false"]
          end
        else
          @root_namespace["false"]
        end
      end

      number.def :is do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if receiver.ruby_value == arg.ruby_value
            @root_namespace["true"]
          else
            @root_namespace["false"]
          end
        else
          @root_namespace["false"]
        end
      end

      number.def :negate do |receiver, arguments|
        receiver.ruby_value = -receiver.ruby_value
        receiver
      end

      number.def :to_string do |receiver, arguments|
        @root_namespace["String"].new_with_value(receiver.ruby_value.to_s)
      end

      number.def :clone do |receiver, arguments|
        if receiver.is_a?("Integer")
          int.new_with_value(receiver.ruby_value)
        elsif receiver.is_a?("Float")
          float.new_with_value(receiver.ruby_value)
        else
          @root_namespace.es_nil
        end
      end
    end

    def load_regex_methods
      regex = @root_namespace["Regex"]

      regex.class_def :new do |receiver, arguments|
        pattern, flags = arguments
        pattern = (pattern ? pattern.ruby_value : "")
        flags = (flags ? flags.ruby_value : nil)
        regex.new_with_value(ESRegex.new(pattern, flags))
      end

      regex.def :pattern do |receiver, arguments|
        @root_namespace["String"].new_with_value(receiver.ruby_value.source)
      end

      regex.def :flags do |receiver, arguments|
        @root_namespace["String"].new_with_value(receiver.ruby_value.flags)
      end

      regex.def :global= do |receiver, arguments|
        t, f = @root_namespace["true"], @root_namespace["false"]
        receiver.ruby_value.global = arguments.first == t ? true : false
        receiver
      end

      regex.def :multiline? do |receiver, arguments|
        t, f = @root_namespace["true"], @root_namespace["false"]
        receiver.ruby_value.multiline? ? t : f
      end

      regex.def :multiline= do |receiver, arguments|
        t, f = @root_namespace["true"], @root_namespace["false"]
        rx = receiver.ruby_value
        if arguments.first == t
          receiver.ruby_value = ESRegex.new(rx.source, rx.flags + "m")
        else
          receiver.ruby_value = ESRegex.new(rx.source, rx.flags.gsub("m", ""))
        end
        receiver
      end

      regex.def :ignorecase? do |receiver, arguments|
        t, f = @root_namespace["true"], @root_namespace["false"]
        receiver.ruby_value.ignorecase? ? t : f
      end

      regex.def :ignorecase= do |receiver, arguments|
        t, f = @root_namespace["true"], @root_namespace["false"]
        rx = receiver.ruby_value
        if arguments.first == t
          receiver.ruby_value = ESRegex.new(rx.source, rx.flags + "i")
        else
          receiver.ruby_value = ESRegex.new(rx.source, rx.flags.gsub("i", ""))
        end
        receiver
      end
    end

    def load_boolean_methods
      true_cls = @root_namespace["TrueClass"]
      false_cls = @root_namespace["FalseClass"]

      true_cls.def :clone do |receiver, arguments|
        true_cls.new_with_value(true)
      end

      false_cls.def :clone do |receiver, arguments|
        false_cls.new_with_value(false)
      end
    end

    def load_nil_methods
      nil_cls = @root_namespace["NilClass"]

      nil_cls.def :clone do |receiver, arguments|
        nil_cls.new_with_value(nil)
      end
    end

    def load_list_methods
      list = @root_namespace["List"]
      list.class_def :new do |receiver, arguments|
        new_list = list.new_with_value(ListBase.new(@root_namespace.es_nil))
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
        val.nil? ? @root_namespace.es_nil : val
      end

      list.def :shift do |receiver, arguments|
        val = receiver.ruby_value.array_value.shift
        val.nil? ? @root_namespace.es_nil : val
      end

      list.def :unshift do |receiver, arguments|
        receiver.ruby_value.array_value.unshift(arguments.first)
        arguments.first
      end

      list.def :keys do |receiver, arguments|
        lst = receiver.ruby_value
        keys = (lst.array_value.length > 0 ? (0...lst.array_value.length).to_a : []).map { |v| @root_namespace["Integer"].new_with_value(v) }
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
        val.nil? ? @root_namespace.es_nil : val
      end

      list.def :length do |receiver, arguments|
        ruby_val = receiver.ruby_value
        length = ruby_val.array_value.length + ruby_val.hash_value.length
        @root_namespace["Integer"].new_with_value(length)
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
        @root_namespace["String"].new_with_value(values.join(str))
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
        @root_namespace["String"].new_with_value("[#{str}]")
      end
    end

    def load_lambda_methods
      lambda = @root_namespace["Lambda"]

      lambda.def :call do |receiver, arguments, context|
        receiver.ruby_value.call(nil, arguments, context)
      end

      lambda.def :apply do |receiver, arguments, context|
        args = arguments.first
        args = if args.is_a?("List")
          arg_list = args.ruby_value.array_value.dup
          arg_list + args.ruby_value.hash_value.map do |k, v|
            @root_namespace["Pair"].call(:new, [k, v])
          end
        else
          []
        end
        receiver.ruby_value.call(nil, args, context)
      end
    end
  end
end