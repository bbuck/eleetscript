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
      nodes.eval(@memory.root_namespace)
    end

    def eval_with_context(code, context)
      nodes = @parser.parse(code)
      nodes.eval(context)
    end

    def load(file_name)
      if File.exists?(file_name)
        eval(File.read(file_name))
      end
    end
  end

  module Helpers
    def self.throw_eleet_error(context, error)
      context.root_ns["Errors"].call("<", [context.root_ns["String"].new_with_value(error, context.namespace_context)])
    end
  end

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

  module Interpolatable
    INTERPOLATE_RX = /[\\]?%(?:@|@@|\$)?[\w]+?(?=\W|$)/

    def interpolate(str, context)
      new_val = str.dup
      matches = str.scan(INTERPOLATE_RX)
      matches.each do |match|
        next if match.nil? || match == "%" || match == ""
        if match.start_with?("\\")
          next new_val.sub!(match, match[1..-1])
        end
        var = match[1..-1]
        new_val.sub!(match, context[var].call(:to_string).ruby_value)
      end
      new_val
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

    def eval(context)
      return_value = nil
      nodes.each do |node|
        if node.kind_of?(ReturnNode)
          returned
          break return_value = node.eval(context)
        elsif node.kind_of?(NextNode)
          nexted
          break
        else
          return_value = node.eval(context)
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
      return_value || context.es_nil
    end
  end

  class StringNode
    include Interpolatable

    def eval(context)
      context.root_ns["String"].new_with_value(interpolate(value, context), context.namespace_context)
    end
  end

  class SymbolNode
    def eval(context)
      context.root_ns["Symbol"].new_with_value(value, context.namespace_context)
    end
  end

  class RegexNode
    include Interpolatable

    def eval(context)
      f_arg = flags.length == 0 ? nil : flags
      context.root_ns["Regex"].new_with_value(ESRegex.new(interpolate(pattern, context), f_arg), context.namespace_context)
    end
  end

  class IntegerNode
    def eval(context)
      context.root_ns["Integer"].new_with_value(value, context.namespace_context)
    end
  end

  class FloatNode
    def eval(context)
      context.root_ns["Float"].new_with_value(value, context.namespace_context)
    end
  end

  class SetGlobalNode
    def eval(context)
      context[name] = value.eval(context)
    end
  end

  class GetGlobalNode
    def eval(context)
      context[name]
    end
  end

  class GetLocalNode
    def eval(context)
      val = context.local_var(name)
      val != context.es_nil ? val : context.current_self.call(name, [])
    end
  end

  class SetLocalNode
    def eval(context)
      if Lexer::RESERVED_WORDS.include?(name)
        Helpers.throw_eleet_error(context, "Cannot assign a value to reserved word \"#{name}\"")
      else
        context.local_var(name, value.eval(context))
      end
    end
  end

  class GetConstantNode
    def eval(context)
      context.constants[name] || context[name]
    end
  end

  class SetConstantNode
    def eval(context)
      if !context.constants.has_key?(name)
        context[name] = value.eval(context)
      else
        Helpers.throw_eleet_error(context, "Cannot reassign constant \"#{name}\" after it's already been defined!")
      end
    end
  end

  class SetInstanceVarNode
    def eval(context)
      context.instance_vars[name] = value.eval(context)
    end
  end

  class GetInstanceVarNode
    def eval(context)
      context.current_self.instance_vars[name]
    end
  end

  class SetClassVarNode
    def eval(context)
      context.current_class.class_vars[name] = value.eval(context)
    end
  end

  class GetClassVarNode
    def eval(context)
      context.current_class.class_vars[name]
    end
  end

  class TrueNode
    def eval(context)
      context.root_ns["true"]
    end
  end

  class FalseNode
    def eval(context)
      context.root_ns["false"]
    end
  end

  class NilNode
    def eval(context)
      context.es_nil
    end
  end

  class ClassNode
    def eval(context)
      cls_name, ns_context, cls = details_from_class_name(context)
      return context.es_nil if cls_name.nil? && ns_context.nil? && cls.nil?
      if cls == context.es_nil
        cls = if parent
          parent_cls = if parent.kind_of?(String)
            context[parent]
          else
            parent.eval(context)
          end
          # TODO: Add to_source for all nodes
          Helpers.throw_eleet_error("Attempt to extend undefined class.", context) if parent_cls == context.es_nil
          EleetScriptClass.create(context, cls_name, parent_cls)
        else
          EleetScriptClass.create(context, cls_name)
        end
        ns_context[cls_name] = cls
      end

      body.eval(cls.context)
      cls
    end

    def details_from_class_name(context)
      if name.kind_of?(String)
        return name, context.namespace_context, context.local_constant(name)
      else
        ns = if name.namespace.nil?
          context.root_ns
        else
          context.namespace(name.namespace)
        end
        exp = name.expression
        while exp.kind_of?(NamespaceAccessNode)
          ns = ns.namespace(exp.namespace)
          exp = exp.expression
        end
        if !exp.kind_of?(GetConstantNode)
          Helpers.throw_eleet_error("Invalid class name given.", context)
          return nil, nil, nil
        end
        return exp.name, ns, ns.local_constant(exp.name)
      end
    end
  end

  class PropertyNode
    def eval(context)
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
    def eval(context)
      value = if receiver
        receiver.eval(context)
      else
        context.current_self
      end
      evaled_args = arguments.map { |a| a.eval(context) }
      evaled_args << lambda.eval(context) if lambda
      value.call(method_name, evaled_args)
    end
  end

  class LambdaNode
    def eval(context)
      context.root_ns["Lambda"].new_with_value(EleetScriptMethod.new(params, body, context), context.namespace_context)
    end
  end

  class DefMethodNode
    def eval(context)
      method_obj = EleetScriptMethod.new(method.params, method.body)
      if context.is_a?(ClassContext)
        context.current_class.methods[method_name] = method_obj
      else
        context.current_self.methods[method_name] = method_obj
      end
      context.es_nil
    end
  end

  class SelfNode
    def eval(context)
      context.current_self
    end
  end

  class IfNode
    include Returnable
    include Nextable

    def eval(context)
      cond = condition.eval(context)
      cond = (cond.class? ? cond : cond.ruby_value)
      if cond
        ret = body.eval(context)
        if body.returnable? && body.returned?
          body.reset_returned
          returned
        elsif body.nextable? && body.nexted?
          body.reset_nexted
          nexted
          return context.es_nil
        end
        ret
      else
        unless else_node.nil?
          ret = else_node.eval(context)
          if else_node.returned?
            else_node.reset_returned
            returned
          elsif else_node.nexted?
            else_node.reset_nexted
            nexted
            return context.es_nil
          end
          ret
        end
      end
    end
  end

  class ElseNode
    include Returnable
    include Nextable

    def eval(context)
      ret = body.eval(context)
      if body.returnable? and body.returned?
        body.reset_returned
        returned
      elsif body.nextable? && body.nexted?
        body.reset_nexted
        nexted
        return context.es_nil
      end
      ret
    end
  end

  class ReturnNode
    def eval(context)
      if expression
        expression.eval(context)
      else
        context.es_nil
      end
    end
  end

  class WhileNode
    include Returnable

    def eval(context)
      val = condition.eval(context)
      ret = nil
      while val.ruby_value
        ret = body.eval(context)
        if body.returnable? && body.returned?
          body.reset_returned
          returned
          return ret
        elsif body.nextable? && body.nexted?
          body.reset_nexted
          next
        end
        val = condition.eval(context)
      end
      ret || context.es_nil
    end
  end

  class NamespaceNode
    def eval(context)
      ns_ctx = context.namespace(name)
      unless ns_ctx
        ns_ctx = context.new_namespace_context
        context.add_namespace(name, ns_ctx)
      end
      body.eval(ns_ctx)
    end
  end

  class NamespaceAccessNode
    def eval(context)
      ns_ctx = if namespace.nil?
        context.root_ns
      else
        context.namespace(namespace)
      end
      if ns_ctx
        expression.eval(ns_ctx)
      else
        Helpers.throw_eleet_error(context, "Namespace \"#{namespace}\" does not exist.")
      end
    end
  end
end