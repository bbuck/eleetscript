require "lang/parser"
require "lang/runtime/memory"

module EleetScript
  class Interpreter
    attr_reader :memory
    def initialize(memory = nil)
      @parser = Parser.new
      @memory = memory || Memory.new
      @memory.bootstrap(self)
    end

    def eval(code, show_nodes = false)
      nodes = @parser.parse(code)
      puts nodes if show_nodes
      nodes.eval(@memory.root_context, @memory)
    end

    def load(file_name)
      if File.exists?(file_name)
        eval(File.read(file_name))
      end
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

  module Returnable
    def returned
      @returned = true
    end

    def returned?
      @returned
    end

    def reset_returned
      @returned = false
    end
  end

  module Nextable
    def nexted
      @nexted = true
    end

    def nexted?
      @nexted
    end

    def reset_nexted
      @nexted = false
    end
  end

  module NodeMethods
    def returnable?
      self.class.included_modules.include?(Returnable)
    end

    def nextable?
      self.class.included_modules.include?(Nextable)
    end
  end

  class Nodes
    include Returnable
    include Nextable

    def eval(context, memory)
      return_value = nil
      nodes.each do |node|
        if node.kind_of?(ReturnNode)
          returned
          break return_value = node.eval(context, memory)
        elsif node.kind_of?(NextNode)
          nexted
          break
        else
          return_value = node.eval(context, memory)
        end
        if node.returnable? && node.returned?
          returned
          node.reset_returned
          break
        elsif node.nextable? && node.nexted?
          node.reset_nexted
          nexted
          break
        end
      end
      return_value || memory.nil_obj
    end
  end

  class StringNode
    INTERPOLATE_RX = /[\\]?%(?:@|@@|\$)?[\w]+?(?=\W|$)/

    def eval(context, memory)
      memory.constants["String"].new_with_value(interpolate(context, memory))
    end

    def interpolate(context, memory)
      new_val = value.dup
      matches = value.scan(INTERPOLATE_RX)
      matches.each do |match|
        next if match.nil? || match == "%" || match == ""
        if match.start_with?("\\")
          next new_val.sub!(match, match[1..-1])
        end
        var = match[1..-1]
        var_value = if var.start_with? "$"
          memory.globals[H::global_name(var)]
        elsif var.start_with? "@@"
          context.class_vars[H::class_var_name(var)]
        elsif var.start_with? "@"
          context.instance_vars[H::instance_var_name(var)]
        elsif var[/\A[A-Z]/]
          (context.constants[var] || memory.constants[var])
        else
          context.locals[var]
        end
        new_val.sub!(match, (var_value.nil? ? memory.nil_obj : var_value).call(:to_string).ruby_value)
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
      context.instance_vars[H::instance_var_name(name)] = value.eval(context, memory)
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

  class NilNode
    def eval(context, memory)
      memory.nil_obj
    end
  end

  class ClassNode
    def eval(context, memory)
      cls = context.constants[name] || memory.constants[name]
      unless cls
        cls = if parent
          parent = context.constants[parent] || memory.constants[parent]
          EleetScriptClass.create(memory, name, parent)
        else
          EleetScriptClass.create(memory, name)
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

  class PropertyNode
    def eval(context, memory)
      cls = context.current_class
      properties.each do |prop_name|
        cls.def "#{prop_name}=" do |receiver, arguments|
          receiver.instance_vars[prop_name] = arguments.first
        end

        cls.def prop_name do |receiver, arguments|
          receiver.instance_vars[prop_name]
        end
      end
    end
  end

  class CallNode
    def eval(context, memory)
      value = if receiver
        receiver.eval(context, memory)
      else
        context.current_self
      end
      evaled_args = arguments.map { |a| a.eval(context, memory) }
      value.call(method_name, evaled_args)
    end
  end

  class DefMethodNode
    def eval(context, memory)
      method_obj = EleetScriptMethod.new(method.params, method.body)
      if method_name.start_with? "@@"
        context.current_class.class_methods[H::class_var_name(method_name)] = method_obj
      else
        context.current_class.instance_methods[method_name] = method_obj
      end
      memory.nil_obj
    end
  end

  class SelfNode
    def eval(context, memory)
      context.current_self
    end
  end

  class IfNode
    include Returnable
    include Nextable

    def eval(context, memory)
      cond = condition.eval(context, memory)
      cond = (cond.class? ? cond : cond.ruby_value)
      if cond
        ret = body.eval(context, memory)
        if body.returnable? && body.returned?
          body.reset_returned
          returned
        elsif body.nextable? && body.nexted?
          body.reset_nexted
          nexted
          return memory.nil_obj
        end
        ret
      else
        unless else_node.nil?
          ret = else_node.eval(context, memory)
          if else_node.returned?
            else_node.reset_returned
            returned
          elsif else_node.nexted?
            else_node.reset_nexted
            nexted
            return memory.nil_obj
          end
          ret
        end
      end
    end
  end

  class ElseNode
    include Returnable
    include Nextable

    def eval(context, memory)
      ret = body.eval(context, memory)
      if body.returnable? and body.returned?
        body.reset_returned
        returned
      elsif body.nextable? && body.nexted?
        body.reset_nexted
        nexted
        return memory.nil_obj
      end
      ret
    end
  end

  class ReturnNode
    def eval(context, memory)
      if expression
        expression.eval(context, memory)
      else
        memory.nil_obj
      end
    end
  end

  class WhileNode
    include Returnable

    def eval(context, memory)
      val = condition.eval(context, memory)
      while val.ruby_value
        ret = body.eval(context, memory)
        if body.returnable? && body.returned?
          body.reset_returned
          returned
          return ret
        elsif body.nextable? && body.nexted?
          body.reset_nexted
          next
        end
        val = condition.eval(context, memory)
      end
      memory.nil_obj
    end
  end
end