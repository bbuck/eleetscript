require "lang/runtime/memory"
require "lang/interpreter"
require "engine/values"

module EleetScript
  class CannotInstantiateBaseEngine < Exception
    def initialize
      super("You cannot instantiate BaseEngine, use SharedEngine or StandaloneEngine")
    end
  end

  class CannotCallInstanceOrClassMethodsExcpetion < Exception
    def initialize
      super("You cannot call a class or instance method using EleetScript::Engine.call")
    end
  end

  class BaseEngine
    def initialize
      raise CannotInstantiateBaseEngine.new
    end

    def evaluate(code)
      begin
        to_ruby_value(eval(code))
      rescue Exception => e
        false
      end
    end

    def execute(code)
      evaluate(code)
    end

    def call(method_name, *args)
      method_name = method_name.to_s
      if method_name =~ /\./
        raise CannotCallInstanceOrClassMethodsException.new
      end
      method_name, ns = unnest(method_name)
      eleet_args = args.map do |arg|
        to_eleet_value(arg)
      end
      to_ruby_value(ns.current_self.call(method_name, eleet_args))
    end

    def [](name)
      load
      var, ns = unnest(name)
      to_ruby_value(ns[name])
    end

    def []=(name, value)
      load
      var, ns = unnest(name)
      if var[0] =~ /[A-Z]/ && ns.constants.has_key?(var)
        memory.root_namespace["Errors"].call("<", [memory.root_namespace["String"].new_with_value("Cannot reassign constant via the Engine.")])
        return false
      else
        ns[var] = to_eleet_value(value)
      end
      true
    end

    def get(var, raw = false)
      val = self[var]
      if raw
        val.eleet_obj
      else
        val
      end
    end

    def set(var, value)
      self[var] = value
    end

    def memory
      @memory ||= Memory.new
    end

    protected

    def load
      interpreter unless @interpreter
    end

    def eval(code)
      interpreter.eval(code)
    end

    def interpreter
      @interpreter ||= Interpreter.new(memory)
    end

    def to_eleet_value(value)
      Values.to_eleet_value(value, self)
    end

    def to_ruby_value(value)
      Values.to_ruby_value(value, self)
    end

    def engine_root_ns
      memory.root_namespace
    end

    def unnest(name)
      if name.start_with?("::")
        name = name[2..-1]
        ns = memory.root_namespace
      else
        ns = engine_root_ns
      end
      nesting = name.split("::")
      var = nesting.pop
      nesting.each do |new_ns|
        ns = ns.namespace(new_ns)
      end
      [var, ns]
    end
  end

  class SharedEngine < BaseEngine
    def initialize; end

    def memory
      @@memory ||= Memory.new
    end

    def reset
      @context = memory.root_namespace.new_namespace_context
    end

    protected

    def eval(code)
      interpreter.eval_with_context(code, context)
    end

    def context
      @context ||= memory.root_namespace.new_namespace_context
    end

    def engine_root_ns
      context
    end
  end

  class Engine < SharedEngine
    def initialize
      super
      puts "WARNING: EleetScript::Engine has been deprecated, please use EleetScript::SharedEngine or EleetScript::StandaloneEngine."
    end
  end

  class StandaloneEngine < BaseEngine
    def initialize; end
  end
end