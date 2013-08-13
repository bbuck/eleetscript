require "lang/parser"
require "lang/runtime/memory"
require "pry"

module Cuby
  class Interpreter
    attr_reader :memory
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

  module InterpHelpers
    def self.global_name(name)
      name[1..-1]
    end

    def self.class_var_name(name)
      name[2..-1]
    end

    def self.instance_var_name(name)
      name[1..-1]
    end
  end
  H = InterpHelpers

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
    INTERPOLATE_RX = /(?<!\\)#\{.*?\}/

    def eval(context, memory)
      memory.constants["String"].new_with_value(interpolate(context, memory))
    end

    def interpolate(context, memory)
      new_val = value.dup
      matches = value.scan(INTERPOLATE_RX)
      matches.each do |match|
        next new_val.sub!(match, "") if match == "\#{}"
        var = match[2..-2]
        if var.start_with? "$"
          new_val.sub!(match, memory.globals[H::global_name(var)].call("to_string").ruby_value)
        elsif var.start_with? "@@"
          new_val.sub!(match, context.current_class.class_vars[H::class_var_name(var)].call("to_string").ruby_value)
        elsif var.start_with? "@"
          new_val.sub!(match, context.current_self.instance_vars[H::instance_var_name(var)].call("to_string").ruby_value)
        elsif var[/\A[A-Z]/]
          new_val.sub!(match, (context.constants[var] || memory.constants[var]).call("to_string").ruby_value)
        else
          new_val.sub!(match, context.locals[var].call("to_string").ruby_value)
        end
      end
      new_val
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

  class GetLocalNode
    def eval(context, memory)
      context.locals[name] || context.current_self.call(name, [])
    end
  end

  class SetLocalNode
    def eval(context, memory)
      context.locals[name] = value.eval(context, memory)
    end
  end

  class GetConstantNode
    def eval(context, memory)
      context.constants[name] || memory.constants[name]
    end
  end

  class SetConstantNode
    def eval(context, memory)
      if context == memory.root_context
        unless memory.constants[name]
          memory.constants[name] = value.eval(context, memory)
        end
      else
        unless context.constants[name]
          context.constants[name] = value.eval(context, memory)
        end
      end
    end
  end

  class SetInstanceVarNode
    def eval(context, memory)
      context.current_self.instance_vars[H::instance_var_name(name)] = value.eval(context, memory)
    end
  end

  class GetInstanceVarNode
    def eval(context, memory)
      context.current_self.instance_vars[H::instance_var_name(name)]
    end
  end

  class TrueNode
    def eval(context, memory)
      memory.constants["true"]
    end
  end

  class FalseNode
    def eval(context, memory)
      memory.constants["false"]
    end
  end

  class ClassNode
    def eval(context, memory)
      cls = context.constants[name] || memory.constants[name]
      unless cls
        cls = if parent
          parent = context.constants[parent] || memory.constants[parent]
          CubyClass.new(memory, parent)
        else
          CubyClass.new(memory)
        end
        if context != memory.root_context
          context.constants[name] = cls
        else
          memory.constants[name] = cls
        end
      end

      body.eval(cls.context, memory)
      cls
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
      if memory.constants.values.include?(value)
        value.call_class(method_name, evaled_args)
      else
        value.call(method_name, evaled_args)
      end
    end
  end

  class DefMethodNode
    def eval(context, memory)
      method_obj = Method.new(method.params, method.body)
      if method_name.start_with? "@@"
        context.current_class.class_methods[H::class_var_name(method_name)] = method_obj
      else
        context.current_class.runtime_methods[method_name] = method_obj
      end
    end
  end
end