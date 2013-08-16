require "cuby"

module Cuby
  module NodeMethods
    def spaces(level)
      "  " * level
    end

    def to_s(level = 0)
      "#{spaces(level)}<#{self.class.name}>\n"
    end

    def is_node?
      true
    end
  end

  class Node < Struct
    include NodeMethods
  end

  class NodeType
    include NodeMethods
  end

  class Nodes < Node.new(:nodes)
    def <<(node)
      nodes << node
      self
    end

    def to_s(level = 0)
      str = "#{spaces(level)}<Cuby::Nodes\n"
      nodes.each do |node|
        str += node.to_s(level + 1)
      end
      str + "#{spaces(level)}>\n"
    end
  end

  class LiteralNode < Node.new(:value)
    def to_s(level = 0)
      "#{spaces(level)}<#{self.class.name} #{value}>\n"
    end
  end

  class IntegerNode < LiteralNode; end
  class FloatNode < LiteralNode; end
  class StringNode < LiteralNode; end

  class TrueNode < LiteralNode
    def value
      true
    end
  end

  class FalseNode < LiteralNode
    def value
      false
    end
  end

  class NilNode < LiteralNode
    def value
      nil
    end
  end

  class CallNode < Node.new(:receiver, :method_name, :arguments, :block)
    def to_s(level = 0)
      tabs = spaces(level)
      str = "#{tabs}<Cuby::CallNode\n"
      if receiver.nil?
        str += "#{tabs}  @receiver=nil\n"
      else
        str += "#{tabs}  @receiver=#{receiver.to_s[0..-2]}\n"
      end
      str += "#{tabs}  @method_name=#{method_name}\n"
      if arguments.empty?
        str += "#{tabs} @arguemtns=empty\n"
      else
        str += "#{tabs}  @arguments=(\n"
        arguments.each do |arg|
          str += arg.to_s(level + 2)
        end
        str += "#{tabs}  )\n"
      end
      if block.nil?
        str + "#{tabs}  @block=nil\n>\n"
      else
        str += "#{tabs}  @block=(\n"
        str += block.to_s(level + 2)
      end
      str + "#{tabs}>\n"
    end
  end

  class SetVarNode < Node.new(:name, :value)
    def to_s(level = 0)
      tabs = spaces(level)
      str = "#{tabs}<#{self.class.name}\n"
      str += "#{tabs}  @name=#{name}\n"
      str += "#{tabs}  @value=(\n"
      str += value.to_s(level + 2)
      str += "#{tabs}>\n"
    end
  end

  class GetVarNode < Node.new(:name)
    def to_s(level = 0)
      str = "<#{self.class.name} \"#{name}\">\n"
    end
  end

  class SetConstantNode < SetVarNode; end
  class GetConstantNode < GetVarNode; end
  class SetGlobalNode < SetVarNode; end
  class GetGlobalNode < GetVarNode; end
  class SetClassVarNode < SetVarNode; end
  class GetClassVarNode < GetVarNode; end
  class SetInstanceVarNode < SetVarNode; end
  class GetInstanceVarNode < GetVarNode; end
  class SetLocalNode < SetVarNode; end
  class GetLocalNode < GetVarNode; end
  class DefMethodNode < Node.new(:method_name, :method)
    def to_s(level = 0)
      tabs = spaces(level)
      str = "#{tabs}<Cuby::DefMethodNode \"#{method_name}\"\n"
      str += "#{tabs}  @method=(\n"
      str += method.to_s(level + 2)
      str + "#{tabs}  )\n#{tabs}>\n"
    end
  end
  class MethodNode < Node.new(:params, :body)
    def to_s(level = 0)
      tabs = spaces(level)
      str = "#{tabs}<Cuby::MethodNode\n"
      str += "#{tabs}  @params=#{params.inspect}\n"
      if body.nodes.length > 0
        str += "#{tabs}  @body=(\n"
        str += body.to_s(level + 2)
        str += "#{tabs}  )\n#{tabs}>\n"
      else
        str += "#{tabs}  @body=nil\n#{tabs}>\n"
      end
      str
    end
  end
  class IfNode < Node.new(:condition, :body, :else_node); end
  class ElseNode < Node.new(:body); end
  class NotNode < Node.new(:value); end
  class WhileNode < Node.new(:condition, :body); end
  class SelfNode < NodeType; end
  class DefinedNode < Node.new(:value); end
  class NamespaceNode < Node.new(:name, :body); end
  class ClassNode < Node.new(:name, :parent, :body)
    def to_s(level = 0)
      tabs = spaces(level)
      str = "#{tabs}<Cuby::ClassNode \"#{name}\"\n"
      str += "#{tabs}  @extends=\"#{parent || "Object"}\"\n"
      str += "#{tabs}  @body=(\n"
      str += body.to_s(level + 2)
      str + "#{tabs}  )\n#{tabs}>\n"
    end
  end
  class ReturnNode < Node.new(:expression); end
  class PropertyNode < Node.new(:properties); end

  class NextNode < NodeType
    def eval(context, memory); end
    def ==(o)
      o.kind_of?(NextNode)
    end
  end

  class NamespaceAccessNode < Node.new(:namespace, :expression); end
end