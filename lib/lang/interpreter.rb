require "lang/parser"
require "lang/runtime/memory"

module Cuby
  class Interpreter
    def initialize
      @memory = Memory.new
      @parser = Parser.new
    end

    def eval(code, show_nodes = false)
      nodes = @parser.parse(code)
      puts nodes if show_nodes
      nodes.eval(@memory.root_context, @memory)
    end
  end

  class Nodes
    def eval(context, memory)
      return_value = nil
      nodes.each do |node|
        return_value = node.eval(context, memory)
      end
      return_value || memory.constants["nil"]
    end
  end

  class StringNode
    def eval(context, memory)
      memory.constants["String"].new_with_value(value)
    end
  end

  class IntegerNode
    def eval(context, memory)
      memory.constants["Integer"].new_with_value(value)
    end
  end

  class FloatNode
    def eval(context, memory)
      memory.constants["Float"].new_with_value(value)
    end
  end

  class SetLocalNode
    def eval(context, memory)
      context.locals[name] = value.eval(context, memory)
    end
  end

  class GetLocalNode
    def eval(context, memory)
      context.locals[name] || context.current_self.call(name, [])
    end
  end

  class CallNode
    def eval(context, memory)
      if receiver
        value = receiver.eval(context, memory)
      else
        value = context.current_self
      end
      evaled_args = arguments.map { |a| a.eval(context, memory) }
      value.call(method_name, evaled_args)
    end
  end

  class DefMethodNode
    def eval(context, memory)
      context.current_class.runtime_methods[method_name] = Method.new(params, body)
    end
  end
end