module EleetScript
  class EleetScriptClassInstance < EleetScriptClassSkeleton
    attr_accessor :instance_vars, :runtime_class, :context
    set_is_instance

    def initialize(class_context, runtime_class)
      @instance_vars = ProcessedKeyHash.new
      @instance_vars.set_key_preprocessor do |key|
        key[0] == "@" ? key[1..-1] : key
      end
      @runtime_class = runtime_class
      @context = class_context.new_instance_context(self)
      @ruby_value = self
    end

    def call(method_name, arguments = [])
      # puts "Calling #{method_name} on #{self}"
      method = @runtime_class.instance_lookup(method_name.to_s)
      if method
        if method.arity == 3
          method.call(self, arguments, @context)
        else
          method.call(self, arguments)
        end
      else
        es_method_name = @context["String"].new_with_value(method_name.to_s)
        call(NO_METHOD, arguments.dup.unshift(es_method_name))
      end
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