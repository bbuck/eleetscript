require "lang/runtime/object"
require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"
require "lang/runtime/array"

module Cuby
  class Memory
    attr_reader :constants, :globals, :root, :root_context

    ROOT_OBJECTS = ["Object", "Integer", "Float", "String", "List", "TrueClass", "FalseClass", "NilClass"]

    def initialize
      @constants = {}
      @globals = {}

      bootstrap
    end

    def nil_method
      @constants["Object"].instance_methods["__nil_method"]
    end

    def nil_obj
      @constants["nil"]
    end

    private

    def bootstrap
      ROOT_OBJECTS.each do |obj_name|
        @constants[obj_name] = CubyClass.create(self, obj_name)
      end

      @root = @constants["Object"].new
      @root_context = Context.new(@root)

      @constants["true"] = @constants["TrueClass"].new_with_value(true)
      @constants["false"] = @constants["FalseClass"].new_with_value(false)
      @constants["nil"] = @constants["NilClass"].new_with_value(nil)

      load_object_methods
      load_string_methods
    end

    def load_object_methods
      object = @constants["Object"]

      object.class_def :new do |receiver, arguments|
        if receiver.class?
          ins = receiver.new
          ins.call("init", arguments)
          ins
        else
          receiver
        end
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

      object.def :__nil_method do |receiver, arguments|
        @constants["nil"]
      end
    end

    def load_string_methods
      string = @constants["String"]

      string.def :to_string do |receiver, arguments|
        receiver
      end
    end
  end
end