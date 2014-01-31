require "lang/runtime/class_skeleton"

module EleetScript
  class EleetScriptClassInstance < EleetScriptClassSkeleton
    attr_accessor :instance_vars, :runtime_class
    set_is_instance

    def call(method_name, arguments = [], lambda = nil)
      method = @runtime_class.instance_lookup(method_name.to_s)
      if method.arity == 4
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

    def eql?(o)
      p self
      p o
      if o.kind_of?(EleetScriptClassInstance)
        if literal_type?
          ruby_value == o.ruby_value
        else
          object_id == o.object_id
        end
      else
        false
      end
    end

    def hash
      if literal_type?
        ruby_value.hash
      else
        call(:to_string).ruby_value.hash
      end
    end

    def literal_type?
      LITERAL_TYPES.include?(class_name)
    end
  end
end