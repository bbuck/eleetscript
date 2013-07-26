require "lang/parser"

describe "Cuby::Parser" do
  let(:parser) { CB::Parser.new }

  describe "literals" do
    it "should parse numbers as integers" do
      code = "10"
      nodes = CB::Nodes.new([CB::IntegerNode.new(10)])
      parser.parse(code).should eq(nodes)
    end

    it "should parse floats as floats" do
      code = "12.345"
      nodes = CB::Nodes.new([CB::FloatNode.new(12.345)])
      parser.parse(code).should eq(nodes)
    end

    describe "strings" do
      it "should be parsed" do
        code = "\"Hello, World\""
        nodes = CB::Nodes.new([CB::StringNode.new("Hello, World")]);
        parser.parse(code).should eq(nodes)
      end

      it "should be parsed with escape characters" do
        code = %( "Hello, \\\"\nWorld" )
        nodes = CB::Nodes.new([CB::StringNode.new("Hello, \"\nWorld")])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "boolean" do
      describe "true" do
        let(:nodes) { nodes = CB::Nodes.new([CB::TrueNode.new]) }

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
        let(:nodes) { CB::Nodes.new([CB::FalseNode.new]) }

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
        nodes = CB::Nodes.new([CB::NilNode.new])
        parser.parse("nil").should eq(nodes)
      end
    end
  end

  describe "variables" do
    describe "constants" do
      it "should parse get requests" do
        code = "CON"
        nodes = CB::Nodes.new([CB::GetConstantNode.new("CON")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "CON = 10"
        nodes = CB::Nodes.new([
                  CB::SetConstantNode.new("CON", CB::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "globals" do
      it "should parse get requests" do
        code = "$con"
        nodes = CB::Nodes.new([CB::GetGlobalNode.new("$con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "$con = 10"
        nodes = CB::Nodes.new([
                  CB::SetGlobalNode.new("$con", CB::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "class" do
      it "should parse get requests" do
        code = "@@con"
        nodes = CB::Nodes.new([CB::GetClassVarNode.new("@@con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "@@con = 10"
        nodes = CB::Nodes.new([
                  CB::SetClassVarNode.new("@@con", CB::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "instance" do
      it "should parse get requests" do
        code = "@con"
        nodes = CB::Nodes.new([CB::GetInstanceVarNode.new("@con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "@con = 10"
        nodes = CB::Nodes.new([
                  CB::SetInstanceVarNode.new("@con", CB::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "local" do
      it "should parse get requests" do
        code = "con"
        nodes = CB::Nodes.new([CB::GetLocalNode.new("con")])
        parser.parse(code).should eq(nodes)
      end

      it "should parse assignments" do
        code = "con = 10"
        nodes = CB::Nodes.new([
                  CB::SetLocalNode.new("con", CB::IntegerNode.new(10))
                ])
        parser.parse(code).should eq(nodes)
      end
    end
  end

  describe "methods" do
    it "should allow one line definitions without params" do
      code = "name do \"Name\" end"
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "name",
                  [],
                  CB::Nodes.new([
                    CB::StringNode.new("Name")
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should allow one line definitions with params" do
      code = "add do |a, b| a + b end"
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "add",
                  ["a", "b"],
                  CB::Nodes.new([
                    CB::CallNode.new(
                      CB::GetLocalNode.new("a"),
                      "+",
                      [CB::GetLocalNode.new("b")]
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
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "name",
                  [],
                  CB::Nodes.new([
                    CB::StringNode.new("Name")
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
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "add",
                  ["a", "b"],
                  CB::Nodes.new([
                    CB::CallNode.new(
                      CB::GetLocalNode.new("a"),
                      "+",
                      [CB::GetLocalNode.new("b")]
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
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "@@test",
                  ["@name"],
                  CB::Nodes.new([
                    CB::IfNode.new(
                      CB::CallNode.new(
                        CB::CallNode.new(
                          CB::GetInstanceVarNode.new("@name"),
                          "length",
                          []
                        ),
                        ">",
                        [CB::IntegerNode.new(7)]
                      ),
                      CB::Nodes.new([
                        CB::CallNode.new(
                          nil,
                          "print",
                          [CB::StringNode.new("Long")]
                        )
                      ]),
                      CB::ElseNode.new(
                        CB::CallNode.new(
                          nil,
                          "print",
                          [CB::StringNode.new("Short")]
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
      nodes = CB::Nodes.new([])
      nodes << CB::IfNode.new(CB::TrueNode.new, CB::Nodes.new([CB::GetLocalNode.new('a')]), nil)
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
      nodes = CB::Nodes.new([])
      inner = CB::Nodes.new([CB::GetLocalNode.new('a'), CB::GetLocalNode.new('b'), CB::GetLocalNode.new('c')])
      nodes << CB::IfNode.new(CB::TrueNode.new, inner, nil)
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
      nodes = CB::Nodes.new([
                CB::WhileNode.new(
                  CB::CallNode.new(
                    CB::GetLocalNode.new("a"),
                    "<",
                    [CB::IntegerNode.new(10)]
                  ),
                  CB::Nodes.new([
                    CB::CallNode.new(
                      CB::GetLocalNode.new("a"),
                      "+=",
                      [CB::IntegerNode.new(10)]
                    ),
                    CB::CallNode.new(
                      nil,
                      "print",
                      [CB::StringNode.new("done")]
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse next tokens" do
      code = <<-CODE
      while 1 < 10
        next
      end
      CODE
      nodes = CB::Nodes.new([
                CB::WhileNode.new(
                  CB::CallNode.new(
                    CB::IntegerNode.new(1),
                    "<",
                    [CB::IntegerNode.new(10)]
                  ),
                  CB::Nodes.new([
                    CB::NextNode.new
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "return statement" do
    it "should be parsed" do
      code = <<-CODE
      test do
        return
      end
      CODE
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "test",
                  [],
                  CB::Nodes.new([
                    CB::ReturnNode.new(nil)
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should be parsed with an expression" do
      code = <<-CODE
      test do |name|
        @names.push(name)
        return name
      end
      CODE
      nodes = CB::Nodes.new([
                CB::DefMethodNode.new(
                  "test",
                  ["name"],
                  CB::Nodes.new([
                    CB::CallNode.new(
                      CB::GetInstanceVarNode.new("@names"),
                      "push",
                      [CB::GetLocalNode.new("name")]
                    ),
                    CB::ReturnNode.new(
                      CB::GetLocalNode.new("name")
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "the property keyword" do
    it "should be parsed" do
      code = <<-CODE
      class Test
        property name
      end
      CODE
      nodes = CB::Nodes.new([
                CB::ClassNode.new(
                  "Test",
                  CB::Nodes.new([
                    CB::PropertyNode.new(["name"])
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should be parsed with multiple identifiers" do
      code = <<-CODE
      class Test
        property one two three
      end
      CODE
      nodes = CB::Nodes.new([
                CB::ClassNode.new(
                  "Test",
                  CB::Nodes.new([
                    CB::PropertyNode.new([
                      "one", "two", "three"
                      ])
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should be parsed with other code" do
      code = <<-CODE
      class Test
        property name
        @@count = 0
        name do
          @@count += 1
          @name
        end
      end
      CODE
      nodes = CB::Nodes.new([
                CB::ClassNode.new(
                  "Test",
                  CB::Nodes.new([
                    CB::PropertyNode.new(["name"]),
                    CB::SetClassVarNode.new("@@count", CB::IntegerNode.new(0)),
                    CB::DefMethodNode.new(
                      "name",
                      [],
                      CB::Nodes.new([
                        CB::CallNode.new(
                          CB::GetClassVarNode.new("@@count"),
                          "+=",
                          [CB::IntegerNode.new(1)]
                        ),
                        CB::GetInstanceVarNode.new("@name")
                      ])
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
      nodes = CB::Nodes.new([
                CB::NamespaceNode.new(
                  "Things",
                  CB::Nodes.new([
                    CB::ClassNode.new(
                      "Math",
                      CB::Nodes.new([
                        CB::DefMethodNode.new(
                          "add",
                          ["a", "b"],
                          CB::Nodes.new([
                            CB::CallNode.new(
                              CB::GetLocalNode.new("a"),
                              "+",
                              [CB::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        CB::DefMethodNode.new(
                          "sub",
                          ["a", "b"],
                          CB::Nodes.new([
                            CB::CallNode.new(
                              CB::GetLocalNode.new("a"),
                              "-",
                              [CB::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        CB::DefMethodNode.new(
                          "div",
                          ["a", "b"],
                          CB::Nodes.new([
                            CB::CallNode.new(
                              CB::GetLocalNode.new("a"),
                              "/",
                              [CB::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        CB::DefMethodNode.new(
                          "mult",
                          ["a", "b"],
                          CB::Nodes.new([
                            CB::CallNode.new(
                              CB::GetLocalNode.new("a"),
                              "*",
                              [CB::GetLocalNode.new("b")]
                            )
                          ])
                        ),
                        CB::DefMethodNode.new(
                          "pow",
                          ["a", "b"],
                          CB::Nodes.new([
                            CB::CallNode.new(
                              CB::GetLocalNode.new("a"),
                              "**",
                              [CB::GetLocalNode.new("b")]
                            )
                          ])
                        )
                      ])
                    )
                  ])
                ),
                CB::SetLocalNode.new(
                  "m",
                  CB::CallNode.new(
                    CB::GetConstantNode.new("Math"),
                    "new",
                    []
                  )
                ),
                CB::SetLocalNode.new(
                  "a",
                  CB::CallNode.new(
                    CB::GetLocalNode.new("m"),
                    "add",
                    [CB::IntegerNode.new(10), CB::IntegerNode.new(20)]
                  )
                ),
                CB::IfNode.new(
                  CB::CallNode.new(
                    CB::GetLocalNode.new("a"),
                    "==",
                    [CB::IntegerNode.new(30)]
                  ),
                  CB::Nodes.new([
                    CB::CallNode.new(
                      nil,
                      "print",
                      [CB::StringNode.new("It works!")]
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end
end