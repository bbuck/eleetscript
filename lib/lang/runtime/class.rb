require "lang/runtime/class_skeleton"

module EleetScript
  NO_METHOD = "no_method"

  class EleetScriptClass < EleetScriptClassSkeleton
    attr_accessor :class_methods, :instance_methods, :class_vars, :context, :name
    attr_reader :super_class, :memory
    set_is_class

    class << self
      def create(memory, name, super_class = nil)
        cls = EleetScriptClass.new(memory, super_class)
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
    alias :class_name :name

    def call(method_name, arguments = [])
      method = lookup(method_name.to_s)
      if method
        if method.kind_of?(EleetScriptMethod)
          method.call(self, arguments, @memory)
        else
          method.call(self, arguments)
        end
      else
        es_method_name = @memory.constants["String"].new_with_value(method_name.to_s)
        call(NO_METHOD, arguments.dup.unshift(es_method_name))
      end
    end

    def lookup(method_name)
      method = @class_methods[method_name]
      if method.nil? && has_super_class?
        return super_class.lookup(method_name)
      end
      method
    end

    def instance_lookup(method_name)
      method = @instance_methods[method_name]
      if method.nil? && has_super_class?
        return super_class.instance_lookup(method_name)
      end
      method
    end

    def super_class
      @super_class || @memory.constants["Object"]
    end

    def def(method_name, es_block = nil, &block)
      method_name = method_name.to_s
      if block_given?
        @instance_methods[method_name] = block
      else
        @instance_methods[method_name] = es_method
      end
    end

    def class_def(method_name, es_block = nil, &block)
      method_name = method_name.to_s
      if block_given?
        @class_methods[method_name] = block
      else
        @class_methods[method_name] = es_method
      end
    end

    def new
      EleetScriptClassInstance.new(@memory, self)
    end

    def new_with_value(value)
      cls = EleetScriptClassInstance.new(@memory, self)
      cls.ruby_value = value
      cls
    end

    def to_s
      "<EleetScriptClass \"#{name || "Unnamed"}\">"
    end

    def inspect
      to_s[0..-2] + " @class_methods(#{@class_methods.keys.join(", ")}) @instance_methods(#{@instance_methods.keys.join(", ")})>"
    end

    def is_a?(value)
      false
    end

    private

    def has_super_class?
      @super_class || (@super_class.nil? && name != "Object")
    end
  end

  class EleetScriptClassInstance < EleetScriptClassSkeleton
    attr_accessor :instance_vars, :runtime_class
    set_is_instance

    def call(method_name, arguments = [])
      method = @runtime_class.instance_lookup(method_name.to_s)
      if method
        if method.kind_of?(EleetScriptMethod)
          method.call(self, arguments, runtime_class.memory)
        else
          method.call(self, arguments)
        end
      else
        es_method_name = @memory.constants["String"].new_with_value(method_name.to_s)
        call(NO_METHOD, arguments.dup.unshift(es_method_name))
      end
    end

    def initialize(memory, runtime_class)
      @instance_vars = {}
      @memory = memory
      @runtime_class = runtime_class
      @ruby_value = self
    end

    def to_s
      "<EleetScriptClassInstance @instance_of=\"#{runtime_class.name || "Unnamed"}\">"
    end

    def inspect
      to_s
    end

    def is_a?(value)
      names = ["Object", runtime_class.name]
      cur_class = runtime_class
      while cur_class.super_class.name != "Object"
        names << cur_class.super_class.name
        cur_class = cur_class.super_class
      end
      names.include?(value)
    end

    def class_name
      @runtime_class.name
    end
  end
end