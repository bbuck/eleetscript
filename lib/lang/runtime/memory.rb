require "lang/runtime/object"
require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "lang/runtime/array"
require "lang/runtime/base_classes"

module Cuby
  class Memory
    attr_reader :constants, :globals, :root, :root_context

    ROOT_OBJECTS = ["Object", "Number", "String", "List", "TrueClass",
                    "FalseClass", "NilClass", "Pair"]

    def initialize
      @constants = {}
      @globals = {}
      @root_path = File.join(File.dirname(__FILE__), "cuby")
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
        @constants[obj_name] = CubyClass.create(self, obj_name)
      end
      @constants["Integer"] = CubyClass.create(self, "Integer", @constants["Number"])
      @constants["Float"] = CubyClass.create(self, "Float", @constants["Number"])

      @root = @constants["Object"].new
      @root_context = Context.new(@root)

      @constants["true"] = @constants["TrueClass"].new_with_value(true)
      @constants["false"] = @constants["FalseClass"].new_with_value(false)
      @constants["nil"] = @constants["NilClass"].new_with_value(nil)

      load_object_methods
      load_string_methods
      load_number_methods
      load_list_methods
      load_boolean_methods
      load_nil_methods
      loader.load(File.join(@root_path, "pair.cb"))
    end

    private

    def load_object_methods
      object = @constants["Object"]

      object.class_def :new do |receiver, arguments|
        ins = receiver.new
        ins.call("init", arguments)
        ins
      end

      object.def :print do |receiver, arguments|
        print arguments.first.call(:to_string).ruby_value
        nil_obj
      end

      object.def :println do |receiver, arguments|
        puts arguments.first.call(:to_string).ruby_value
        nil_obj
      end

      object.def :to_string do |receiver, arguments|
        cls_name = receiver.runtime_class.name
        @constants["String"].new_with_value(cls_name)
      end

      object.def :inspect do |receiver, arguments|
        receiver.call(:to_string)
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

      object.def :__nil_method do |receiver, arguments|
        @constants["nil"]
      end

      object.def :class_name do |receiver, arguments|
        @constants["String"].new_with_value(receiver.runtime_class.name)
      end
    end

    def load_string_methods
      string = @constants["String"]

      string.def :to_string do |receiver, arguments|
        receiver
      end

      string.def :inspect do |receiver, arguments|
        @constants["String"].new_with_value('"' + receiver.ruby_value + '"')
      end
    end

    def load_number_methods
      number = @constants["Number"]
      int = @constants["Integer"]
      float = @constants["Float"]

      number.def "+" do |receiver, arguments|
        arg = arguments.first
        val = receiver.ruby_value + arg.ruby_value
        if val.kind_of?(Fixnum)
          int.new_with_value(val)
        else
          float.new_with_value(val)
        end
      end

      number.def :to_string do |receiver, arguments|
        @constants["String"].new_with_value(receiver.ruby_value.to_s)
      end
    end

    def load_list_methods
      list = @constants["List"]
      list.class_def :new do |receiver, arguments|
        new_list = list.new_with_value(ListBase.new(nil_obj))
        arguments.each do |arg|
          if arg.instance? && arg.runtime_class.name == "Pair"
            new_list.ruby_value.hash[arg.call(:key).call(:to_string).ruby_value] = arg.call(:value)
          else
            new_list.ruby_value.array << arg
          end
        end
        new_list
      end

      list.def "[]" do |receiver, arguments|
        lst = receiver.ruby_value
        arg = arguments.first
        if arg.instance? && arg.runtime_class.name == "Integer"
          index = arg.ruby_value
          if index < lst.array.length
            lst.array[index]
          else
            lst.hash[arg.ruby_value]
          end
        else
          if arg.instance?
            lst.hash[arg.call(:to_string).ruby_value]
          else
            lst.hash[arg]
          end
        end
      end

      list.def "[]=" do |receiver, arguments|
        lst = receiver.ruby_value
        key = arguments.first
        value = arguments[1]
        if key.instance? && key.runtime_class.name == "Integer"
          index = key.ruby_value
          if index < lst.array.length
            lst.array[index] = value
          else
            lst.hash[key.ruby_value] = value
          end
        else
          if key.instance?
            lst.hash[key.call(:to_string).ruby_value] = value
          else
            lst.hash[key] = value
          end
        end
        value
      end

      list.def :push do |receiver, arguments|
        receiver.ruby_value.array << arguments.first
        arguments.first
      end

      list.def :pop do |receiver, arguments|
        val = receiver.ruby_value.array.pop
        val.nil? ? nil_obj : val
      end

      list.def :shift do |receiver, arguments|
        val = receiver.ruby_value.array.shift
        val.nil? ? nil_obj : val
      end

      list.def :unshift do |receiver, arguments|
        reciever.ruby_value.array.unshift(arguments.first)
        arguments.first
      end

      list.def :keys do |receiver, arguments|
        lst = receiver.ruby_value
        keys = (lst.array.length > 0 ? (0...lst.array.length).to_a : [])
        keys.concat(lst.hash.keys)
        list.call(:new, keys)
      end

      list.def :values do |receiver, arguments|
        lst = receiver.ruby_value
        vals = (lst.array.length > 0 ? lst.array.dup : [])
        vals.concat(lst.hash.values)
        list.call(:new, vals)
      end

      list.def :length do |receiver, arguments|
        length = receiver.ruby_value.array.length + receiver.ruby_value.length
        @constants["Integer"].new_with_value(length)
      end

      list.def :delete do |receiver, arguments|
        val = receiver.ruby_value.hash.delete(arguments.first)
        val.nil? ? nil_obj : val
      end

      list.def :to_string do |receiver, arguments|
        arr_vals = receiver.ruby_value.array.map do |val|
          val.call(:inspect).ruby_value
        end
        arr_str = arr_vals.join(", ")
        hash_vals = receiver.ruby_value.hash.map do |k, v|
          if k.kind_of?(CubyClassSkeleton)
            k = k.call(:inspect).ruby_value
          else
            k = k.to_s
          end
          "#{k}=>#{v.call(:to_string).ruby_value}"
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

    def load_boolean_methods
      true_class = @constants["TrueClass"]
      false_class = @constants["FalseClass"]
      true_class.def :to_string do |receiver, arguments|
        @constants["String"].new_with_value("true")
      end

      false_class.def :to_string do |receiver, arguments|
        @constants["String"].new_with_value("false")
      end
    end

    def load_nil_methods
      nil_class = @constants["NilClass"]

      nil_class.def :to_string do |receiver, arguments|
        @constants["String"].new_with_value("nil")
      end
    end
  end
end