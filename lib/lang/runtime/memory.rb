require "lang/runtime/object"
require "lang/runtime/class"
require "lang/runtime/context"
require "lang/runtime/method"

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
      CubyClass.memory = self
      @constants["Class"] = CubyClass.new
      @constants["Class"].runtime_class = @constants["Class"]
      @constants["Object"] = CubyClass.new
      @constants["Integer"] = CubyClass.new
      @constants["Float"] = CubyClass.new
      @constants["String"] = CubyClass.new

      @root = @constants["Object"].new
      @root_context = Context.new(@root)

      @constants["TrueClass"] = CubyClass.new
      @constants["FalseClass"] = CubyClass.new
      @constants["NilClass"] = CubyClass.new

      @constants["true"] = @constants["TrueClass"].new_with_value(true)
      @constants["false"] = @constants["FalseClass"].new_with_value(false)
      @constants["nil"] = @constants["NilClass"].new_with_value(true)

      @constants["Class"].def :new do |reciever, arguments|
        receiver.new
      end

      @constants["Object"].def :print do |receiver, arguments|
        print arguments.first.ruby_value
        @constants["nil"]
      end

      @constants["Object"].def :__nil_method do |reciever, arguments|
        @constants["nil"]
      end

      @constants["Object"].def :println do |receiver, arguments|
        puts arguments.first.ruby_value
        @constants["nil"]
      end
    end
  end
end