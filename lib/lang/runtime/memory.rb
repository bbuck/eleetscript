require "lang/runtime/object"
require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "lang/runtime/array"

module Cuby
  class Memory
    attr_reader :constants, :globals, :root, :root_context

    def initialize
      @constants = {}
      @globals = {}

      bootstrap
    end

    private

    def bootstrap
      @constants["Class"] = CubyClass.new(self)
      @constants["Class"].runtime_class = @constants["Class"]
      @constants["Object"] = CubyClass.new(self)
      @constants["Object"].name = "Object"
      @constants["Integer"] = CubyClass.new(self)
      @constants["Integer"].name = "Integer"
      @constants["Float"] = CubyClass.new(self)
      @constants["Float"].name = "Float"
      @constants["String"] = CubyClass.new(self)
      @constants["String"].name = "String"
      @constants["Array"] = CubyArray.new(self)
      @constants["Array"].name = "Array"

      @root = @constants["Object"].new
      @root_context = Context.new(@root)

      @constants["TrueClass"] = CubyClass.new(self)
      @constants["TrueClass"].name = "TrueClass"
      @constants["FalseClass"] = CubyClass.new(self)
      @constants["FalseClass"].name = "FalseClass"
      @constants["NilClass"] = CubyClass.new(self)
      @constants["NilClass"].name = "NilClass"

      @constants["true"] = @constants["TrueClass"].new_with_value(true)
      @constants["false"] = @constants["FalseClass"].new_with_value(false)
      @constants["nil"] = @constants["NilClass"].new_with_value(nil)

      load_class_methods
      load_object_methods
      load_string_methods
      load_integer_methods
      load_array_methods
    end

    def load_class_methods
      cls = @constants["Class"]
      cls.def_class :new do |receiver, arguments|
        cls = receiver.new
        cls.call("init", arguments)
        cls
      end

      cls.def :name do |receiver, arguments|
        @constants["String"].new_with_value(reciever.runtime_class.name)
      end
    end

    def load_object_methods
      object = @constants["Object"]
      object.def :init do |receiver, arguments|
        @constants["nil"]
      end

      object.def :to_string do |receiver, arguments|
        receiver.call(:name).call(:to_string)
      end

      object.def :__nil_method do |receiver, arguments|
        @constants["nil"]
      end

      object.def :print do |receiver, arguments|
        print arguments.first.call("to_string").ruby_value
        @constants["nil"]
      end

      object.def :println do |receiver, arguments|
        puts arguments.first.call("to_string").ruby_value
        @constants["nil"]
      end

      object.def :class do |receiver, arguments|
        receiver.runtime_class
      end
    end

    def load_string_methods
      string = @constants["String"]

      string.def :to_string do |receiver, arguments|
        receiver
      end
    end

    def get_number_class(other)
      if other.runtime_class == @constants["Float"]
        @constants["Float"]
      elsif other.runtime_class == @constants["Integer"]
        @constants["Integer"]
      else
        nil
      end
    end

    def load_integer_methods
      integer = @constants["Integer"]
      integer.def "+" do |receiver, arguments|
        other = arguments.first
        result = receiver.ruby_value + other.ruby_value
        if other.runtime_class == @constants["Float"]
          @constants["Float"].new_with_value(result)
        elsif other.runtime_class == @constants["Integer"]
          @constants["Integer"].new_with_value(result)
        else
          @constants["nil"]
        end
      end
    end

    def value_to_array_key(value)
      type = value.call(:name)
      case type
      when "Integer", "Float", "String"
        value.ruby_value
      else
        value.call(:to_string)
      end
    end

    def load_array_methods
      array = @constants["Array"]
      array.def :at do |receiver, arguments|
        cls = receiver.runtime_class
        index = arguments.length > 0 ? arguments.first : nil
        if index
          type = index.call("name")
          if type == "Integer"
            index = index.ruby_value
            if index > cls.array.length
              cls.hash[index] || @constants["nil"]
            else
              cls.array[index]
            end
          else
            key = value_to_array_key(index)
            cls.hash[key] || @constants["nil"]
          end
        else
          @constants["nil"]
        end
      end

      array.def :push do |receiver, arguments|
        cls = receiver.runtime_class
        arguments.each do |arg|
          cls.array << arg
        end
      end

      array.def :set do |receiver, arguments|
        cls = receiver.runtime_class
        key, value = arguments
        if key.call(:name) == "Integer"
          if key.ruby_value < cls.array.length
            cls.array.length[key.ruby_value] = value
            return
          end
        end
        key = value_to_array_key(key)
        cls.hash[key] = value
      end

      array.def :length do |receiver, arguments|
        @constants["Integer"].new_with_value(cls.array.length + cls.hash.keys.length)
      end
    end
  end
end