require "lang/parser"

describe "EleetScript::Parser" do
  let(:parser) { ES::Parser.new }

  describe "literals" do
    it "should parse numbers as integers" do
      code = "10"
      nodes = ES::Nodes.new([ES::IntegerNode.new(10)])
      parser.parse(code).should eq(nodes)
    end

    it "should parse floats as floats" do
      code = "12.345"
      nodes = ES::Nodes.new([ES::FloatNode.new(12.345)])
      parser.parse(code).should eq(nodes)
    end

    describe "strings" do
      it "should be parsed" do
        code = "\"Hello, World\""
        nodes = ES::Nodes.new([ES::StringNode.new("Hello, World")]);
        parser.parse(code).should eq(nodes)
      end

      it "should be parsed with escape characters" do
        code = %( "Hello, \\\"\nWorld" )
        nodes = ES::Nodes.new([ES::StringNode.new("Hello, \"\nWorld")])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "boolean" do
      describe "true" do
        let(:nodes) { nodes = ES::Nodes.new([ES::TrueNode.new]) }

        it "should be parsed" do
          parser.parse("true").should eq(nodes)
        end

        it "should be parsed from 'yes'" do
          parser.parse("yes").should eq(nodes)
        end

        it "should be parsed from 'on'" do
          parser.parse("on").should eq(nodes)
        end
      end

      describe "false" do
        let(:nodes) { ES::Nodes.new([ES::FalseNode.new]) }

        it "should be parsed" do
          parser.parse("false").should eq(nodes)
        end

        it "should be parsed from 'no'" do
          parser.parse("no").should eq(nodes)
        end

        it "should be parsed from 'off'" do
          parser.parse("off").should eq(nodes)
        end
      end
    end

    describe "nil" do
      it "should be parsed" do
        nodes = ES::Nodes.new([ES::NilNode.new])
        parser.parse("nil").should eq(nodes)
      end
    end
  end

  describe "variables" do
    describe "constants" do
      it "should parse get requests" do
        code = "CON"
        nodes = ES::Nodes.new([ES::GetConstantNode.new("CON")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "CON = 10"
        nodes = ES::Nodes.new([
                  ES::SetConstantNode.new("CON", ES::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "globals" do
      it "should parse get requests" do
        code = "$con"
        nodes = ES::Nodes.new([ES::GetGlobalNode.new("$con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "$con = 10"
        nodes = ES::Nodes.new([
                  ES::SetGlobalNode.new("$con", ES::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "class" do
      it "should parse get requests" do
        code = "@@con"
        nodes = ES::Nodes.new([ES::GetClassVarNode.new("@@con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "@@con = 10"
        nodes = ES::Nodes.new([
                  ES::SetClassVarNode.new("@@con", ES::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "instance" do
      it "should parse get requests" do
        code = "@con"
        nodes = ES::Nodes.new([ES::GetInstanceVarNode.new("@con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "@con = 10"
        nodes = ES::Nodes.new([
                  ES::SetInstanceVarNode.new("@con", ES::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "local" do
      it "should parse get requests" do
        code = "con"
        nodes = ES::Nodes.new([ES::GetLocalNode.new("con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "con = 10"
        nodes = ES::Nodes.new([
                  ES::SetLocalNode.new("con", ES::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end
  end

  describe "methods" do
    it "should allow one line definitions without params" do
      code = "name do \"Name\" end"
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "name",
                  [],
                  ES::Nodes.new([
                    ES::StringNode.new("Name")
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should allow one line definitions with params" do
      code = "add do |a, b| a + b end"
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "add",
                  ["a", "b"],
                  ES::Nodes.new([
                    ES::CallNode.new(
                      ES::GetLocalNode.new("a"),
                      "+",
                      [ES::GetLocalNode.new("b")]
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse simple definitions" do
      code = <<-CODE
      name do
        "Name"
      end
      CODE
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "name",
                  [],
                  ES::Nodes.new([
                    ES::StringNode.new("Name")
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse definitions with params" do
      code = <<-CODE
      add do |a, b|
        a + b
      end
      CODE
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "add",
                  ["a", "b"],
                  ES::Nodes.new([
                    ES::CallNode.new(
                      ES::GetLocalNode.new("a"),
                      "+",
                      [ES::GetLocalNode.new("b")]
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should allow definitions with complex expressions inside" do
      code = <<-CODE
      @@test do |@name|
        if @name.length > 7
          print("Long")
        else
          print("Short")
        end
      end
      CODE
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "@@test",
                  ["@name"],
                  ES::Nodes.new([
                    ES::IfNode.new(
                      ES::CallNode.new(
                        ES::CallNode.new(
                          ES::GetInstanceVarNode.new("@name"),
                          "length",
                          []
                        ),
                        ">",
                        [ES::IntegerNode.new(7)]
                      ),
                      ES::Nodes.new([
                        ES::CallNode.new(
                          nil,
                          "print",
                          [ES::StringNode.new("Long")]
                        )
                      ]),
                      ES::ElseNode.new(
                        ES::CallNode.new(
                          nil,
                          "print",
                          [ES::StringNode.new("Short")]
                        )
                      )
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "if statments" do
    it "should allow for simple statements" do
      code = <<-CODE
      if true
        a
      end
      CODE
      nodes = ES::Nodes.new([])
      nodes << ES::IfNode.new(ES::TrueNode.new, ES::Nodes.new([ES::GetLocalNode.new('a')]), nil)
      parser.parse(code).should eq(nodes)
    end

    it "should allow for multiple expressions inside" do
      code = <<-CODE
      if true
        a
        b
        c
      end
      CODE
      nodes = ES::Nodes.new([])
      inner = ES::Nodes.new([ES::GetLocalNode.new('a'), ES::GetLocalNode.new('b'), ES::GetLocalNode.new('c')])
      nodes << ES::IfNode.new(ES::TrueNode.new, inner, nil)
      parser.parse(code).should eq(nodes)
    end
  end

  describe "while loop" do
    it "should be parsed" do
      code = <<-CODE
      while a < 10
        a += 10
        print("done")
      end
      CODE
      nodes = ES::Nodes.new([
                ES::WhileNode.new(
                  ES::CallNode.new(
                    ES::GetLocalNode.new("a"),
                    "<",
                    [ES::IntegerNode.new(10)]
                  ),
                  ES::Nodes.new([
                    ES::CallNode.new(
                      ES::GetLocalNode.new("a"),
                      "+=",
                      [ES::IntegerNode.new(10)]
                    ),
                    ES::CallNode.new(
                      nil,
                      "print",
                      [ES::StringNode.new("done")]
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "full programs" do
    it "should be parsed" do
      code = <<-CODE
      namespace Things
        class Math
          add do |a, b|
            a + b
          end

          sub do |a, b|
            a - b
          end

          div do |a, b|
            a / b
          end

          mult do |a, b|
            a * b
          end

          pow do |a, b|
            a ** b
          end
        end
      end

      m = Math.new
      a = m.add(10, 20)
      if a == 30
        print("It works!")
      end
      CODE
      nodes = ES::Nodes.new([
                ES::NamespaceNode.new(
                  "Things",
                  ES::Nodes.new([
                    ES::ClassNode.new(
                      "Math",
                      ES::Nodes.new([
                        ES::DefMethodNode.new(
                          "add",
                          ["a", "b"],
                          ES::Nodes.new([
                            ES::CallNode.new(
                              ES::GetLocalNode.new("a"),
                              "+",
                              [ES::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        ES::DefMethodNode.new(
                          "sub",
                          ["a", "b"],
                          ES::Nodes.new([
                            ES::CallNode.new(
                              ES::GetLocalNode.new("a"),
                              "-",
                              [ES::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        ES::DefMethodNode.new(
                          "div",
                          ["a", "b"],
                          ES::Nodes.new([
                            ES::CallNode.new(
                              ES::GetLocalNode.new("a"),
                              "/",
                              [ES::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        ES::DefMethodNode.new(
                          "mult",
                          ["a", "b"],
                          ES::Nodes.new([
                            ES::CallNode.new(
                              ES::GetLocalNode.new("a"),
                              "*",
                              [ES::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        ES::DefMethodNode.new(
                          "pow",
                          ["a", "b"],
                          ES::Nodes.new([
                            ES::CallNode.new(
                              ES::GetLocalNode.new("a"),
                              "**",
                              [ES::GetLocalNode.new("b")]
                            )
                          ])
                        )
                      ])
                    )
                  ])
                ),
                ES::SetLocalNode.new(
                  "m",
                  ES::CallNode.new(
                    ES::GetConstantNode.new("Math"),
                    "new",
                    []
                  )
                ),
                ES::SetLocalNode.new(
                  "a",
                  ES::CallNode.new(
                    ES::GetLocalNode.new("m"),
                    "add",
                    [ES::IntegerNode.new(10), ES::IntegerNode.new(20)]
                  )
                ),
                ES::IfNode.new(
                  ES::CallNode.new(
                    ES::GetLocalNode.new("a"),
                    "==",
                    [ES::IntegerNode.new(30)]
                  ),
                  ES::Nodes.new([
                    ES::CallNode.new(
                      nil,
                      "print",
                      [ES::StringNode.new("It works!")]
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end
end