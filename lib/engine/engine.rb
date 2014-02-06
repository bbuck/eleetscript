require "lang/runtime/memory"
require "lang/interpreter"
require "engine/values"

module EleetScript
  class CannotCallInstanceOrClassMethodsExcpetion < Exception
  end

  class Engine
    def initialize
      @memory = Memory.new
      @interpreter = Interpreter.new(@memory)
    end

    def execute(code)
      begin
        to_ruby_value(@interpreter.eval(code))
      rescue Exception => e
        false
      end
    end

    def call(method_name, *args)
      method_name = method_name.to_s
      if method_name =~ /\./
        throw CannotCallInstanceOrClassMethodsException.new("You cannot call a class or instance method using EleetScript::Engine.call")
      end
      nesting = method_name.split("::")
      ns = @memory.root_namespace
      method_name = nesting.pop
      nesting.each do |new_ns|
        ns = ns.namespace(new_ns)
      end
      eleet_args = args.each do |arg|
        to_eleet_value(arg, self)
      end
      to_ruby_value(ns.current_self.call(method_name, eleet_args))
    end

    def get(var, raw = false)
      value = @memory.root_namespace[var]
      if raw
        value
      else
        to_ruby_value(value)
      end
    end

    def set(var, value)
      nesting = var.split("::")
      ns = @memory.root_namespace
      var = nesting.pop
      nesting.each do |new_ns|
        ns = ns.namespace(new_ns)
      end
      if var[0] =~ /[A-Z]/
        if ns.constants.has_key?(var)
          @memory.root_namespace["Errors"].call("<", [@memory.root_namespace["String"].new_with_value("Cannot reassign constant via the Engine.")])
          return false
        else
          ns[var] = to_eleet_value(value)
        end
      else
        ns[var] = to_eleet_value(value)
      end
      true
    end

    def to_eleet_value(value)
      Values.to_eleet_value(value, self)
    end

    def to_ruby_value(value)
      Values.to_ruby_value(value, self)
    end
  end
end