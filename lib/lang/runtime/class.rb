module Cuby
  class CubyClassSkeleton
    attr_accessor :ruby_value
    attr_reader :memory

    class << self
      def set_is_instance
        self.class_eval do
          def instance?
            true
          end
        end
      end

      def set_is_class
        self.class_eval do
          def class?
            true
          end
        end
      end
    end

    def instance?
      false
    end

    def class?
      false
    end
  end

  class CubyClass < CubyClassSkeleton
    attr_accessor :class_methods, :instance_methods, :class_vars, :context, :name
    attr_reader :super_class, :memory
    set_is_class

    class << self
      def create(memory, name, super_class = nil)
        cls = CubyClass.new(memory, super_class)
        cls.name = name
        cls
      end
    end

    def initialize(memory, super_class = nil)
      @class_methods = {}
      @instance_methods = {}
      @class_vars = {}
      @context = Context.new(self, self)
      @memory = memory
      @super_class = super_class
      @ruby_value = self
    end

    def call(method_name, arguments = [])
      method = lookup(method_name.to_s)
      if method.kind_of?(CubyMethod)
        method.call(self, arguments, @memory)
      else
        method.call(self, arguments)
      end
    end

    def lookup(method_name)
      method = @class_methods[method_name]
      if method.nil? && has_super_class?
        return super_class.lookup(method_name)
      end
      method || @memory.nil_method
    end

    def instance_lookup(method_name)
      method = @instance_methods[method_name]
      if method.nil? && has_super_class?
        return super_class.instance_lookup(method_name)
      end
      method || @memory.nil_method
    end

    def super_class
      @super_class || @memory.constants["Object"]
    end

    def def(method_name, cuby_block = nil, &block)
      method_name = method_name.to_s
      if block_given?
        @instance_methods[method_name] = block
      else
        @instance_methods[method_name] = cuby_method
      end
    end

    def class_def(method_name, cuby_block = nil, &block)
      method_name = method_name.to_s
      if block_given?
        @class_methods[method_name] = block
      else
        @class_methods[method_name] = cuby_method
      end
    end

    def new
      CubyClassInstance.new(@memory, self)
    end

    def new_with_value(value)
      cls = CubyClassInstance.new(@memory, self)
      cls.ruby_value = value
      cls
    end

    def to_s
      "<CubyClass \"#{name || "Unnamed"}\">"
    end

    def inspect
      to_s[0..-2] + " @class_methods(#{@class_methods.keys.join(", ")}) @instance_methods(#{@instance_methods.keys.join(", ")})>"
    end

    private

    def has_super_class?
      @super_class || (@super_class.nil? && name != "Object")
    end
  end

  class CubyClassInstance < CubyClassSkeleton
    attr_accessor :instance_vars, :runtime_class
    set_is_instance

    def call(method_name, arguments = [])
      method = @runtime_class.instance_lookup(method_name.to_s)
      if method.kind_of?(CubyMethod)
        method.call(self, arguments, runtime_class.memory)
      else
        method.call(self, arguments)
      end
    end

    def initialize(memory, runtime_class)
      @instance_vars = {}
      @memory = memory
      @runtime_class = runtime_class
      @ruby_value = self
    end

    def to_s
      "<CubyClassInstance @instance_of=\"#{runtime_class.name || "Unnamed"}\">"
    end

    def inspect
      to_s
    end
  end
end