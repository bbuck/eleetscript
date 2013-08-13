module Cuby
  class CubyClass < CubyObject
    attr_accessor :runtime_methods, :class_methods, :context, :name
    attr_reader :memory, :class_vars

    def initialize(memory, super_class = nil)
      @memory = memory
      @runtime_methods = {}
      @class_methods = {}
      @context = Context.new(self, self)
      @runtime_class = default_runtime_class
      @name = "Class"
      @super_class = super_class || nil
    end

    def lookup(method_name)
      method = @runtime_methods[method_name]
      unless method
        if @super_class
          return @super_class.lookup(method_name)
        elsif self != @memory.constants["Object"]
          return @memory.constants["Object"].lookup(method_name)
        end
      end
      method || @memory.constants["Object"].runtime_methods["__nil_method"]
    end

    def lookup_class(method_name)
      method = @class_methods[method_name]
      unless method
        if @super_class
          return @super_class.lookup_class(method_name)
        elsif self != @memory.constants["Object"]
          return @memory.constants["Object"].lookup_class(method_name)
        end
      end
      method || @memory.constants["Object"].runtime_methods["__nil_method"]
    end

    def def(name, &block)
      @runtime_methods[name.to_s] = block
    end

    def def_class(name, &block)
      @class_methods[name.to_s] = block
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

    def to_s
      "<CubyClass>"
    end
  end
end