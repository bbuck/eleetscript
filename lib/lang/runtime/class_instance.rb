module EleetScript
  class EleetScriptClassInstance < EleetScriptClassSkeleton
    attr_accessor :instance_vars, :runtime_class, :context, :methods
    set_is_instance

    def initialize(class_context, runtime_class, namespace_context)
      @methods = MethodHash.new
      @instance_vars = ProcessedKeyHash.new
      @instance_vars.set_key_preprocessor do |key|
        key[0] == "@" ? key[1..-1] : key
      end
      @runtime_class = runtime_class
      @context = class_context.new_instance_context(self, namespace_context)
      @ruby_value = self
    end

    def es_responds_to?(method_name)
      !find_method(method_name).nil?
    end

    def call(method_name, arguments = [])
      method = find_method(method_name)
      call_method(method_name, method, arguments)
    end

    def super_call(method_name, arguments = [])
      kls = @runtime_class
      super_kls = kls.super_class
      if kls == super_kls
        str = @context['String'].new_with_value(
          "Cannot call super implementation for #{method_name} without a super class",
          @context
        )
        @context['Errors'].call(:<, str)
        @context['nil']
      else
        method = super_kls.instance_lookup(method_name)
        call_method(method_name, method, arguments)
      end
    end

    def find_method(method_name)
      method = @methods[method_name]
      if method.nil?
        method = @runtime_class.instance_lookup(method_name.to_s)
      end
      method
    end

    def to_s
      "<EleetScriptClassInstance @instance_of=\"#{runtime_class.name || "Unnamed"}\">"
    end

    def inspect
      to_s
    end

    def is_a?(*values)
      names = ["Object", runtime_class.name]
      cur_class = runtime_class
      while cur_class.super_class.name != "Object"
        names << cur_class.super_class.name
        cur_class = cur_class.super_class
      end
      values.each do |value|
        return true if names.include?(value)
      end
      false
    end

    def class_name
      @runtime_class.name
    end

    private

    def call_method(method_name, method, arguments)
      if method
        if method.arity == 3
          method.call(self, arguments, @context)
        else
          method.call(self, arguments)
        end
      else
        es_method_name = @context["String"].new_with_value(method_name.to_s, @context.namespace_context)
        call(NO_METHOD, arguments.dup.unshift(es_method_name))
      end
    end
  end
end
