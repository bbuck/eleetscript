require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "lang/runtime/array"
require "lang/runtime/base_classes"

module EleetScript
  class Memory
    attr_reader :constants, :globals, :root, :root_context

    ROOT_OBJECTS = ["Object", "Number", "String", "List", "TrueClass", "IO",
                    "FalseClass", "NilClass"]

    def initialize
      @constants = {}
      @globals = {}
      @root_path = File.join(File.dirname(__FILE__), "eleetscript")
    end

    def nil_method
      @constants["Object"].instance_methods["__nil_method"]
    end

    def nil_obj
      @constants["nil"]
    end

    def bootstrap(loader)
      return if @bootstrapped
      @bootstrapped = true

      ROOT_OBJECTS.each do |obj_name|
        @constants[obj_name] = EleetScriptClass.create(self, obj_name)
      end
      @constants["Integer"] = EleetScriptClass.create(self, "Integer", @constants["Number"])
      @constants["Float"] = EleetScriptClass.create(self, "Float", @constants["Number"])

      @root = @constants["Object"].new
      @root_context = Context.new(@root)

      @constants["true"] = @constants["TrueClass"].new_with_value(true)
      @constants["false"] = @constants["FalseClass"].new_with_value(false)
      @constants["nil"] = @constants["NilClass"].new_with_value(nil)

      load_object_methods
      load_io_methods
      load_string_methods
      load_number_methods
      load_boolean_methods
      load_nil_methods
      load_list_methods
      files = Dir.glob(File.join(@root_path, "**", "*.es"))
      files.each do |file|
        loader.load(file)
      end
    end

    private

    def load_object_methods
      object = @constants["Object"]

      object.class_def :new do |receiver, arguments|
        ins = receiver.new
        ins.call("init", arguments)
        ins
      end

      object.def :kind_of? do |receiver, arguments|
        t = @constants["true"]
        f = @constants["false"]
        if arguments.length == 0 || !arguments.first.class?
          return f
        end
        names = []
        names << receiver.runtime_class.name
        cur_class = receiver.runtime_class
        while @constants["Object"] != cur_class.super_class
          names << cur_class.super_class.name
          cur_class = cur_class.super_class
        end
        names << "Object" # Base of everything
        name = arguments.first.name
        names.include?(name) ? t : f
      end

      object.def :class_name do |receiver, arguments|
        @constants["String"].new_with_value(receiver.runtime_class.name)
      end

      object.class_def :class_name do |receiver, arguments|
        @constants["String"].new_with_value(receiver.name)
      end

      object.def :is do |receiver, arguments|
        if receiver == arguments.first
          @constants["true"]
        else
          @constants["false"]
        end
      end

      object.def :clone do |receiver, arguments|
        cls_name = receiver.runtime_class.name
        if ["Integer", "Float", "String", "List"].include?(cls_name)
          receiver.runtime_class.new_with_value(receiver.ruby_value.dup)
        else
          ins = reciever.runtime_class.call(:new)
          ins.ruby_value = receiver.ruby_value.dup
        end
      end
    end

    def load_io_methods
      io = @constants["IO"]

      io.class_def :print do |receiver, arguments|
        print arguments.first.call(:to_string).ruby_value
        nil_obj
      end

      io.class_def :println do |receiver, arguments|
        puts arguments.first.call(:to_string).ruby_value
        nil_obj
      end

      io.class_def :new do |receiver, arguments|
        io
      end
    end

    def load_string_methods
      string = @constants["String"]

      string.def "+" do |receiver, arguments|
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

      string.def "is" do |receiver, arguments|
        compare_to = arguments.first.ruby_value
        if compare_to == receiver.ruby_value
          constants["true"]
        else
          constants["false"]
        end
      end

      string.def "substr" do |receiver, arguments|
        if arguments.length < 2
          constants["nil"]
        else
          s, e = arguments
          if s.is_a?("Integer") && e.is_a?("Integer")
            range = if e.ruby_value < 0
              (s.ruby_value..e.ruby_value)
            else
              (s.ruby_value...e.ruby_value)
            end
            constants["String"].new_with_value(receiver.ruby_value[range])
          else
            constants["nil"]
          end
        end
      end
    end

    def load_number_methods
      number = @constants["Number"]
      int = @constants["Integer"]
      float = @constants["Float"]

      number.def "+" do |receiver, arguments|
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
          @constants["String"].new_with_value(str)
        else
          receiver
        end
      end

      number.def "-" do |receiver, arguments|
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

      number.def "*" do |receiver, arguments|
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

      number.def "/" do |receiver, arguments|
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

      number.def "%" do |receiver, arguments|
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

      number.def "<" do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if receiver.ruby_value < arg.ruby_value
            @constants["true"]
          else
            @constants["false"]
          end
        else
          @constants["false"]
        end
      end

      number.def ">" do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if receiver.ruby_value > arg.ruby_value
            @constants["true"]
          else
            @constants["false"]
          end
        else
          @constants["false"]
        end
      end

      number.def "is" do |receiver, arguments|
        arg = arguments.first
        if arg.is_a?("Number")
          if receiver.ruby_value == arg.ruby_value
            @constants["true"]
          else
            @constants["false"]
          end
        else
          @constants["false"]
        end
      end

      number.def "__negate!" do |receiver, arguments|
        receiver.ruby_value = -receiver.ruby_value
        receiver
      end

      number.def :to_string do |receiver, arguments|
        @constants["String"].new_with_value(receiver.ruby_value.to_s)
      end

      number.def :clone do |receiver, arguments|
        if receiver.is_a?("Integer")
          int.new_with_value(receiver.ruby_value)
        elsif receiver.is_a?("Float")
          float.new_with_value(receiver.ruby_value)
        else
          nil_obj
        end
      end
    end

    def load_boolean_methods
      true_cls = @constants["TrueClass"]
      false_cls = @constants["FalseClass"]

      true_cls.def :clone do |receiver, arguments|
        true_cls.new_with_value(true)
      end

      false_cls.def :clone do |receiver, arguments|
        false_cls.new_with_value(false)
      end
    end

    def load_nil_methods
      nil_cls = @constants["NilClass"]

      nil_cls.def :clone do |receiver, arguments|
        nil_cls.new_with_value(nil)
      end
    end

    def load_list_methods
      list = @constants["List"]
      list.class_def :new do |receiver, arguments|
        new_list = list.new_with_value(ListBase.new(nil_obj))
        arguments.each do |arg|
          if arg.instance? && arg.runtime_class.name == "Pair"
            new_list.ruby_value.hash_value[arg.call(:key)] = arg.call(:value)
          else
            new_list.ruby_value.array_value << arg
          end
        end
        new_list
      end

      list.def "[]" do |receiver, arguments|
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

      list.def "[]=" do |receiver, arguments|
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
        val.nil? ? nil_obj : val
      end

      list.def :shift do |receiver, arguments|
        val = receiver.ruby_value.array_value.shift
        val.nil? ? nil_obj : val
      end

      list.def :unshift do |receiver, arguments|
        reciever.ruby_value.array_value.unshift(arguments.first)
        arguments.first
      end

      list.def :keys do |receiver, arguments|
        lst = receiver.ruby_value
        keys = (lst.array_value.length > 0 ? (0...lst.array_value.length).to_a : [])
        keys.concat(lst.hash_value.keys)
        list.call(:new, keys)
      end

      list.def :values do |receiver, arguments|
        lst = receiver.ruby_value
        vals = (lst.array_value.length > 0 ? lst.array_value.dup : [])
        vals.concat(lst.hash_value.values)
        list.call(:new, vals)
      end

      list.def :length do |receiver, arguments|
        length = receiver.ruby_value.array_value.length + receiver.ruby_value.length
        @constants["Integer"].new_with_value(length)
      end

      list.def :delete do |receiver, arguments|
        val = receiver.ruby_value.hash_value.delete(arguments.first)
        val.nil? ? nil_obj : val
      end

      list.def :length do |receiver, arguments|
        ruby_val = receiver.ruby_value
        length = ruby_val.array_value.length + ruby_val.hash_value.length
        @constants["Integer"].new_with_value(length)
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
        @constants["String"].new_with_value("[#{str}]")
      end
    end
  end
end