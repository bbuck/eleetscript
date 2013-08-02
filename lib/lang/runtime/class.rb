module Cuby
  class CubyClass < CubyObject
    attr_accessor :runtime_methods, :context, :name
    attr_reader :memory, :class_vars

    def initialize(memory, super_class = nil)
      @memory = memory
      @runtime_methods = {}
      @context = Context.new(self, self)
      @runtime_class = default_runtime_class
      @name = "Class"
      @super_class = super_class || default_super_class
    end

    def lookup(method_name)
      method = @runtime_methods[method_name]
      unless method
        if @super_class && @super_class != self
          return @super_class.lookup(method_name)
        end
      end
      method || @memory.constants["Object"].runtime_methods["__nil_method"]
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

    private

    def default_super_class
      @memory.constants["Object"] || self
    end

    def default_runtime_class
      @memory.constants["Class"] || self
    end
  end
end