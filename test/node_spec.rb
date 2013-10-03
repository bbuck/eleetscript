require "lang/nodes"

describe "EleetScript syntax nodes" do
  describe "Nodes class should contain list of nodes" do
    it "should exist" do
      (defined?(ES::Nodes) == "constant" && ES::Nodes.class == Class).should be_true
    end

    it "should respond to 'nodes'" do
      ES::Nodes.new.should respond_to(:nodes)
    end

    it "should allow concatenation like an array" do
      nodes = ES::Nodes.new([])
      nodes << "a"
      nodes.nodes.should eq(["a"])
    end
  end

  describe "literal nodes" do
    it "should respond to value" do
      ES::LiteralNode.new.should respond_to(:value)
    end

    describe "string" do
      it "should exist" do
        (defined?(ES::StringNode) == "constant" && ES::StringNode.class == Class).should be_true
      end

      it "should respond to value" do
        ES::StringNode.new.should respond_to(:value)
      end

      it "should store and return a string value" do
        str = ES::StringNode.new("string value")
        str.value.should be_kind_of(String)
      end
    end

    describe "numbers" do
      describe "integers" do
        it "should exist" do
          (defined?(ES::IntegerNode) == "constant" && ES::IntegerNode.class == Class).should be_true
        end

        it "should respond to 'value'" do
          ES::IntegerNode.new.should respond_to(:value)
        end

        it "should store and return Fixnum" do
          node = ES::IntegerNode.new(10)
          node.value.should be_kind_of(Fixnum)
        end
      end

      describe "floats" do
        it "should exist" do
          (defined?(ES::FloatNode) == "constant" && ES::FloatNode.class == Class).should be_true
        end

        it "should respond to 'value'" do
          ES::FloatNode.new.should respond_to(:value)
        end

        it "should store and return Fixnum" do
          node = ES::FloatNode.new(10.134)
          node.value.should be_kind_of(Float)
        end
      end
    end

    describe "true node" do
      it "should exist" do
        (defined?(ES::TrueNode) == "constant" && ES::TrueNode.class == Class).should be_true
      end

      it "should respond to value" do
        ES::TrueNode.new.should respond_to(:value)
      end

      it "should return true regardless of what is passed to it" do
        node = ES::TrueNode.new(false)
        node.value.should be_true
      end
    end

    describe "false node" do
      it "should exist" do
        (defined?(ES::FalseNode) == "constant" && ES::FalseNode.class == Class).should be_true
      end

      it "should respond to value" do
        ES::FalseNode.new.should respond_to(:value)
      end

      it "should return false regardless of what is passed to it" do
        node = ES::FalseNode.new(true)
        node.value.should be_false
      end
    end

    describe "nil node" do
      it "should exist" do
        (defined?(ES::NilNode) == "constant" && ES::NilNode.class == Class).should be_true
      end

      it "should respond to value" do
        ES::NilNode.new.should respond_to(:value)
      end

      it "should return nil regardless of what is passed to it" do
        node = ES::NilNode.new(false)
        node.value.should be_nil
      end
    end
  end

  describe "call node" do
    it "should exist" do
      (defined?(ES::CallNode) == "constant" && ES::CallNode.class == Class).should be_true
    end

    it "should respond to 'receiver'" do
      ES::CallNode.new.should respond_to(:receiver)
    end

    it "should respond to 'method_name'" do
      ES::CallNode.new.should respond_to(:method_name)
    end

    it "should respond to 'arguments'" do
      ES::CallNode.new.should respond_to(:arguments)
    end
  end

  describe "constants" do
    describe "set constant node" do
      it "should exist" do
        (defined?(ES::SetConstantNode) == "constant" && ES::SetConstantNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::SetConstantNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        ES::SetConstantNode.new.should respond_to(:value)
      end
    end

    describe "get constant node" do
      it "should exist" do
        (defined?(ES::GetConstantNode) == "constant" && ES::GetConstantNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::GetConstantNode.new.should respond_to(:name)
      end
    end
  end

  describe "globals" do
    describe "set global node" do
      it "should exist" do
        (defined?(ES::SetGlobalNode) == "constant" && ES::SetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::SetGlobalNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        ES::SetGlobalNode.new.should respond_to(:value)
      end
    end

    describe "get global node" do
      it "should exist" do
        (defined?(ES::GetGlobalNode) == "constant" && ES::GetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::GetGlobalNode.new.should respond_to(:name)
      end
    end
  end

  describe "globals" do
    describe "set global node" do
      it "should exist" do
        (defined?(ES::SetGlobalNode) == "constant" && ES::SetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::SetGlobalNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        ES::SetGlobalNode.new.should respond_to(:value)
      end
    end

    describe "get global node" do
      it "should exist" do
        (defined?(ES::GetGlobalNode) == "constant" && ES::GetGlobalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::GetGlobalNode.new.should respond_to(:name)
      end
    end
  end

  describe "class variables" do
    describe "set class var node" do
      it "should exist" do
        (defined?(ES::SetClassVarNode) == "constant" && ES::SetClassVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::SetClassVarNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        ES::SetClassVarNode.new.should respond_to(:value)
      end
    end

    describe "get class var node" do
      it "should exist" do
        (defined?(ES::GetClassVarNode) == "constant" && ES::GetClassVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::GetClassVarNode.new.should respond_to(:name)
      end
    end
  end

  describe "instance variables" do
    describe "set instance var node" do
      it "should exist" do
        (defined?(ES::SetInstanceVarNode) == "constant" && ES::SetInstanceVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::SetInstanceVarNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        ES::SetInstanceVarNode.new.should respond_to(:value)
      end
    end

    describe "get instance var node" do
      it "should exist" do
        (defined?(ES::GetInstanceVarNode) == "constant" && ES::GetInstanceVarNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::GetInstanceVarNode.new.should respond_to(:name)
      end
    end
  end

  describe "locals" do
    describe "set local node" do
      it "should exist" do
        (defined?(ES::SetLocalNode) == "constant" && ES::SetLocalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::SetLocalNode.new.should respond_to(:name)
      end

      it "should respond to 'value'" do
        ES::SetLocalNode.new.should respond_to(:value)
      end
    end

    describe "get local node" do
      it "should exist" do
        (defined?(ES::GetLocalNode) == "constant" && ES::GetLocalNode.class == Class).should be_true
      end

      it "should respond to 'name'" do
        ES::GetLocalNode.new.should respond_to(:name)
      end
    end
  end

  describe "define method node" do
    it "should exist" do
      (defined?(ES::DefMethodNode) == "constant" && ES::DefMethodNode.class == Class).should be_true
    end

    it "should respond to 'method_name'" do
      ES::DefMethodNode.new.should respond_to(:method_name)
    end

    it "should respond to 'body'" do
      ES::DefMethodNode.new.should respond_to(:method)
    end
  end

  describe "method node" do
    it "should respond to 'params'" do
      ES::MethodNode.new.should respond_to(:params)
    end

    it "should respond to 'body'" do
      ES::MethodNode.new.should respond_to(:body)
    end
  end

  describe "if node" do
    it "should exist" do
      (defined?(ES::IfNode) == "constant" && ES::IfNode.class == Class).should be_true
    end

    it "should respond to 'condition'" do
      ES::IfNode.new.should respond_to(:condition)
    end

    it "should respond to 'body'" do
      ES::IfNode.new.should respond_to(:body)
    end

    it "should respond to 'else_node'" do
      ES::IfNode.new.should respond_to(:else_node)
    end
  end

  describe "else node" do
    it "should exist" do
      (defined?(ES::ElseNode) == "constant" && ES::ElseNode.class == Class).should be_true
    end

    it "should respond to 'body'" do
      ES::ElseNode.new.should respond_to(:body)
    end
  end

  describe "not node" do
    it "should exist" do
      (defined?(ES::NotNode) == "constant" && ES::NotNode.class == Class).should be_true
    end

    it "should respond to 'value'" do
      ES::NotNode.new.should respond_to(:value)
    end
  end

  describe "while node" do
    it "should exist" do
      (defined?(ES::WhileNode) == "constant" && ES::WhileNode.class == Class).should be_true
    end

    it "should respond to 'condition'" do
      ES::WhileNode.new.should respond_to(:condition)
    end

    it "should respond to 'body'" do
      ES::WhileNode.new.should respond_to(:body)
    end
  end

  describe "self node" do
    it "should exist" do
      (defined?(ES::SelfNode) == "constant" && ES::SelfNode.class == Class).should be_true
    end
  end

  describe "defined node" do
    it "should exist" do
      (defined?(ES::DefinedNode) == "constant" && ES::DefinedNode.class == Class).should be_true
    end

    it "should respond to 'value'" do
      ES::DefinedNode.new.should respond_to(:value)
    end
  end

  describe "namespace node" do
    it "should exist" do
      (defined?(ES::NamespaceNode) == "constant" && ES::NamespaceNode.class == Class).should be_true
    end

    it "should respond to 'name'" do
      ES::NamespaceNode.new.should respond_to(:name)
    end

    it "should respond to 'body'" do
      ES::NamespaceNode.new.should respond_to(:body)
    end
  end

  describe "class node" do
    it "should exist" do
      (defined?(ES::ClassNode) == "constant" && ES::ClassNode.class == Class).should be_true
    end

    it "should respond to 'name'" do
      ES::ClassNode.new.should respond_to(:name)
    end

    it "should respond to 'body'" do
      ES::ClassNode.new.should respond_to(:body)
    end
  end
end