require "eleetscript"

module Cuby
  class Nodes < Struct.new(:nodes)
    def <<(node)
      nodes << node
      self
    end
  end

  class LiteralNode < Struct.new(:value); end
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

  class CallNode < Struct.new(:receiver, :method_name, :arguments); end
  class SetVarNode < Struct.new(:name, :value); end
  class GetVarNode < Struct.new(:name); end
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
  class DefMethodNode < Struct.new(:method_name, :params, :body); end
  class IfNode < Struct.new(:condition, :body, :else_node); end
  class ElseNode < Struct.new(:body); end
  class NotNode < Struct.new(:value); end
  class WhileNode < Struct.new(:condition, :body); end
  class SelfNode; end
  class DefinedNode < Struct.new(:value); end
  class NamespaceNode < Struct.new(:name, :body); end
  class ClassNode < Struct.new(:name, :body); end
end