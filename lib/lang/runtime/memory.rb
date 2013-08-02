require "lang/runtime/object"
require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "pry"

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
      @constants["nil"] = @constants["NilClass"].new_with_value(true)

      load_class_methods
      load_object_methods
      load_integer_methods
    end

    def load_class_methods
      cls = @constants["Class"]
      cls.def :new do |receiver, arguments|
        cls = receiver.new
        cls.call("init", arguments)
        cls
      end

      cls.def :name do |receiver, arguments|
        reciever.runtime_class.name
      end
    end

    def load_object_methods
      object = @constants["Object"]
      object.def :init do |receiver, arguments|
        nil
      end

      object.def :to_string do |receiver, arguments|
        receiver.ruby_value.to_s
      end

      object.def :__nil_method do |receiver, arguments|
        @constants["nil"]
      end

      object.def :print do |receiver, arguments|
        print arguments.first.call("to_string")
        @constants["nil"]
      end

      object.def :println do |receiver, arguments|
        puts arguments.first.call("to_string")
        @constants["nil"]
      end

      object.def :class do |receiver, arguments|
        receiver.runtime_class
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
  end
end