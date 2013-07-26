require "lang/nodes"

describe "Cuby syntax nodes" do
  describe "Nodes class should contain list of nodes" do
    it "should exist" do
      (defined?(CB::Nodes) == "constant" && CB::Nodes.class == Class).should be_true
    end

    it "should respond to 'nodes'" do
      CB::Nodes.new.should respond_to(:nodes)
    end

    it "should allow concatenation like an array" do
      nodes = CB::Nodes.new([])
      nodes << "a"
      nodes.nodes.should eq(["a"])
    end
  end

  describe "literal nodes" do
    it "should respond to value" do
      CB::LiteralNode.new.should respond_to(:value)
    end

    describe "string" do
      it "should exist" do
        (defined?(CB::StringNode) == "constant" && CB::StringNode.class == Class).should be_true
      end

      it "should respond to value" do
        CB::StringNode.new.should respond_to(:value)
      end

      it "should store and return a string value" do
        str = CB::StringNode.new("string value")
        str.value.should be_kind_of(String)
      end
    end

    describe "numbers" do
      describe "integers" do
        it "should exist" do
          (defined?(CB::IntegerNode) == "constant" && CB::IntegerNode.class == Class).should be_true
        end

        it "should respond to 'value'" do
          CB::IntegerNode.new.should respond_to(:value)
        end

        it "should store and return Fixnum" do
          node = CB::IntegerNode.new(10)
          node.value.should be_kind_of(Fixnum)
        end
      end

      describe "floats" do
        it "should exist" do
          (defined?(CB::FloatNode) == "constant" && CB::FloatNode.class == Class).should be_true
        end

        it "should respond to 'value'" do
          CB::FloatNode.new.should respond_to(:value)
        end

        it "should store and return Fixnum" do
          node = CB::FloatNode.new(10.134)
          node.value.should be_kind_of(Float)
        end
      end
    end

    describe "true node" do
      it "should exist" do
        (defined?(CB::TrueNode) == "constant" && CB::TrueNode.class == Class).should be_true
      end

      it "should respond to value" do
        CB::TrueNode.new.should respond_to(:value)
      end

      it "should return true regardless of what is passed to it" do
        node = CB::TrueNode.new(false)
        node.value.should be_true
      end
    end

    describe "false node" do
      it "should exist" do
        (defined?(CB::FalseNode) == "constant" && CB::FalseNode.class == Class).should be_true
      end

      it "should respond to value" do
        CB::FalseNode.new.should respond_to(:value)
      end

      it "should return false regardless of what is passed to it" do
        node = CB::FalseNode.new(true)
        node.value.should be_false
      end
    end

    describe "nil node" do
      it "should exist" do
        (defined?(CB::NilNode) == "constant" && CB::NilNode.class == Class).should be_true
      end

      it "should respond to value" do
        CB::NilNode.new.should respond_to(:value)
      end

      it "should return nil regardless of what is passed to it" do
        node = CB::NilNode.new(false)
        node.value.should be_nil
      end
    end
  end

  describe "call node" do
    it "should exist" do
      (defined?(CB::CallNode) == "constant" && CB::CallNode.class == Class).should be_true
    end

    it "should respond to 'receiver'" do
      CB::CallNode.new.should respond_to(:receiver)
    end

    it "should respond to 'method_name'" do
      CB::CallNode.new.should respond_to(:method_name)
    end

    it "should respond to 'arguments'" do
      CB::CallNode.new.should respond_to(:arguments)
    end
  end

  describe "constants" do
    describe "set constant node" do
      it "should exist" do
        (defined?(CB::SetConstantNode) == "constant" && CB::SetConstantNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::SetConstantNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        CB::SetConstantNode.new.should respond_to(:value)
      end
    end

    describe "get constant node" do
      it "should exist" do
        (defined?(CB::GetConstantNode) == "constant" && CB::GetConstantNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::GetConstantNode.new.should respond_to(:name)
      end
    end
  end

  describe "globals" do
    describe "set global node" do
      it "should exist" do
        (defined?(CB::SetGlobalNode) == "constant" && CB::SetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::SetGlobalNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        CB::SetGlobalNode.new.should respond_to(:value)
      end
    end

    describe "get global node" do
      it "should exist" do
        (defined?(CB::GetGlobalNode) == "constant" && CB::GetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::GetGlobalNode.new.should respond_to(:name)
      end
    end
  end

  describe "globals" do
    describe "set global node" do
      it "should exist" do
        (defined?(CB::SetGlobalNode) == "constant" && CB::SetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::SetGlobalNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        CB::SetGlobalNode.new.should respond_to(:value)
      end
    end

    describe "get global node" do
      it "should exist" do
        (defined?(CB::GetGlobalNode) == "constant" && CB::GetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::GetGlobalNode.new.should respond_to(:name)
      end
    end
  end

  describe "class variables" do
    describe "set class var node" do
      it "should exist" do
        (defined?(CB::SetClassVarNode) == "constant" && CB::SetClassVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::SetClassVarNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        CB::SetClassVarNode.new.should respond_to(:value)
      end
    end

    describe "get class var node" do
      it "should exist" do
        (defined?(CB::GetClassVarNode) == "constant" && CB::GetClassVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::GetClassVarNode.new.should respond_to(:name)
      end
    end
  end

  describe "instance variables" do
    describe "set instance var node" do
      it "should exist" do
        (defined?(CB::SetInstanceVarNode) == "constant" && CB::SetInstanceVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::SetInstanceVarNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        CB::SetInstanceVarNode.new.should respond_to(:value)
      end
    end

    describe "get instance var node" do
      it "should exist" do
        (defined?(CB::GetInstanceVarNode) == "constant" && CB::GetInstanceVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::GetInstanceVarNode.new.should respond_to(:name)
      end
    end
  end

  describe "locals" do
    describe "set local node" do
      it "should exist" do
        (defined?(CB::SetLocalNode) == "constant" && CB::SetLocalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::SetLocalNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        CB::SetLocalNode.new.should respond_to(:value)
      end
    end

    describe "get local node" do
      it "should exist" do
        (defined?(CB::GetLocalNode) == "constant" && CB::GetLocalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        CB::GetLocalNode.new.should respond_to(:name)
      end
    end
  end

  describe "define method node" do
    it "should exist" do
      (defined?(CB::DefMethodNode) == "constant" && CB::DefMethodNode.class == Class).should be_true
    end

    it "should respond to 'method_name'" do
      CB::DefMethodNode.new.should respond_to(:method_name)
    end

    it "should respond to 'params'" do
      CB::DefMethodNode.new.should respond_to(:params)
    end

    it "should respond to 'body'" do
      CB::DefMethodNode.new.should respond_to(:body)
    end
  end

  describe "if node" do
    it "should exist" do
      (defined?(CB::IfNode) == "constant" && CB::IfNode.class == Class).should be_true
    end

    it "should respond to 'condition'" do
      CB::IfNode.new.should respond_to(:condition)
    end

    it "should respond to 'body'" do
      CB::IfNode.new.should respond_to(:body)
    end

    it "should respond to 'else_node'" do
      CB::IfNode.new.should respond_to(:else_node)
    end
  end

  describe "else node" do
    it "should exist" do
      (defined?(CB::ElseNode) == "constant" && CB::ElseNode.class == Class).should be_true
    end

    it "should respond to 'body'" do
      CB::ElseNode.new.should respond_to(:body)
    end
  end

  describe "not node" do
    it "should exist" do
      (defined?(CB::NotNode) == "constant" && CB::NotNode.class == Class).should be_true
    end

    it "should respond to 'value'" do
      CB::NotNode.new.should respond_to(:value)
    end
  end

  describe "while node" do
    it "should exist" do
      (defined?(CB::WhileNode) == "constant" && CB::WhileNode.class == Class).should be_true
    end

    it "should respond to 'condition'" do
      CB::WhileNode.new.should respond_to(:condition)
    end

    it "should respond to 'body'" do
      CB::WhileNode.new.should respond_to(:body)
    end
  end

  describe "self node" do
    it "should exist" do
      (defined?(CB::SelfNode) == "constant" && CB::SelfNode.class == Class).should be_true
    end
  end

  describe "defined node" do
    it "should exist" do
      (defined?(CB::DefinedNode) == "constant" && CB::DefinedNode.class == Class).should be_true
    end

    it "should respond to 'value'" do
      CB::DefinedNode.new.should respond_to(:value)
    end
  end

  describe "namespace node" do
    it "should exist" do
      (defined?(CB::NamespaceNode) == "constant" && CB::NamespaceNode.class == Class).should be_true
    end

    it "should respond to 'name'" do
      CB::NamespaceNode.new.should respond_to(:name)
    end

    it "should respond to 'body'" do
      CB::NamespaceNode.new.should respond_to(:body)
    end
  end

  describe "class node" do
    it "should exist" do
      (defined?(CB::ClassNode) == "constant" && CB::ClassNode.class == Class).should be_true
    end

    it "should respond to 'name'" do
      CB::ClassNode.new.should respond_to(:name)
    end

    it "should respond to 'body'" do
      CB::ClassNode.new.should respond_to(:body)
    end
  end
end