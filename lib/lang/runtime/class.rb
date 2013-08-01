module Cuby
  class CubyClass < CubyObject
    class << self
      def memory=(memory)
        @@memory = memory
      end
    end

    attr_accessor :runtime_methods, :class_vars

    def initialize(super_class = nil)
      raise "Memory not set, cannot execut properly!" unless @@memory
      @runtime_methods = {}
      @runtime_class = @@memory.constants["Class"]
      @super_class = super_class || @@memory.constants["Object"]
    end

    def lookup(method_name)
      method = @runtime_methods[method_name]
      unless method
        if @super_class
          return @super_class.lookup(method_name)
        end
      end
      method || @@memory.constants["Object"].runtime_methods["__nil_method"]
    end

    def def(name, &block)
      @runtime_methods[name.to_s] = block
    end

    def new
      CubyObject.new(self)
    end

    def new_with_value(value)
      CubyObject.new(self, value)
    end

    def memory
      @@memory
    end
  end
end