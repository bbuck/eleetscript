require "lang/runtime/memory"
require "lang/interpreter"
require "engine/values"

module EleetScript
  class Engine
    def initialize
      @memory = Memory.new
      @interpreter = Interpreter.new(@memory)
    end

    def execute(code)
      to_ruby_value(@interpreter.eval(code))
    end

    def call(method, *args)
      # TODO: Finish
      to_ruby_value(@interpreter.eval("#{method.to_s}"))
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