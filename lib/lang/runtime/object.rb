module Cuby
  # Represents a Cuby object in Ruby memory
  class CubyObject
    attr_accessor :runtime_class, :ruby_value
    attr_reader :instance_vars

    def initialize(runtime_class, ruby_value = self)
      @instance_vars = {}
      @runtime_class = runtime_class
      @ruby_value = ruby_value
    end

    def call(method, arguments = [])
      method = method.to_s
      method = @runtime_class.lookup(method)
      method.call(self, arguments)
    end

    def call_class(method, arguments = [])
      method = method.to_s
      method = @runtime_class.lookup_class(method)
      method.call(self, arguments)
    end

    def to_s
      "<CubyObject>"
    end
  end
end