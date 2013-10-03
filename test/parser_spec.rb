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

    describe "pairs" do
      it "should be parsed" do
        code = "\"key\" => \"value\""
        nodes = ES::Nodes.new([
                  ES::CallNode.new(
                    ES::GetConstantNode.new("Pair"),
                    "new",
                    [
                      ES::StringNode.new("key"),
                      ES::StringNode.new("value")
                    ]
                  )
                ])
        parser.parse(code).should eq(nodes)
      end
    end

    describe "lists" do
      it "should parse literal lists" do
        code = "[1, 2, 3, 4]"
        nodes = ES::Nodes.new([
                  ES::CallNode.new(
                    ES::GetConstantNode.new("List"),
                    "new",
                    [
                      ES::IntegerNode.new(1),
                      ES::IntegerNode.new(2),
                      ES::IntegerNode.new(3),
                      ES::IntegerNode.new(4)
                    ]
                  )
                ]
              )
        parser.parse(code).should eq(nodes)
      end

      it "should handle empty lists too" do
        code = "a = []"
        nodes = ES::Nodes.new([
                  ES::SetLocalNode.new(
                    "a",
                    ES::CallNode.new(
                      ES::GetConstantNode.new("List"),
                      "new",
                      []
                    )
                  )
                ])
        parser.parse(code).should eq(nodes)
      end

      it "should provide the same results for sugarless syntax" do
        with_sugar = "[1, 2, 3, 4]"
        without_sugar = "List.new(1, 2, 3, 4)"
        parser.parse(with_sugar).should eq(parser.parse(without_sugar))
      end

      it "should accept pairs" do
        code = "[\"key\" => \"value\"]"
        nodes = ES::Nodes.new([
                  ES::CallNode.new(
                    ES::GetConstantNode.new("List"),
                    "new",
                    [
                      ES::CallNode.new(
                        ES::GetConstantNode.new("Pair"),
                        "new",
                        [
                          ES::StringNode.new("key"),
                          ES::StringNode.new("value")
                        ]
                      )
                    ]
                  )
                ])
        parser.parse(code).should eq(nodes)
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

    describe "operators" do
      describe "should be function calls" do
        let(:nodes) {
          ES::Nodes.new([
            ES::CallNode.new(
              ES::GetLocalNode.new("one"),
              "+",
              [ES::GetLocalNode.new("two")]
            )
          ])
        }

        it "should treat them like functions when used like functions" do
          code = "one.+(two)"
          parser.parse(code).should eq(nodes)
        end

        it "should do the same but with syntatic sugar" do
          code = "one + two"
          parser.parse(code).should eq(nodes)
        end
      end

      describe "list specific" do
        it "should call [] when list accessors are used" do
          code = "one[two]"
          nodes = ES::Nodes.new([
                    ES::CallNode.new(
                      ES::GetLocalNode.new("one"),
                      "[]",
                      [ES::GetLocalNode.new("two")]
                    )
                  ])
          parser.parse(code).should eq(nodes)
        end

        it "should do the same for assignment" do
          code = "one[\"two\"] = three"
          nodes = ES::Nodes.new([
                    ES::CallNode.new(
                      ES::GetLocalNode.new("one"),
                      "[]=",
                      [
                        ES::StringNode.new("two"),
                        ES::GetLocalNode.new("three")
                      ]
                    )
                  ])
          parser.parse(code).should eq(nodes)
        end
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

    describe "assignment method calls" do
      let(:nodes) {
        ES::Nodes.new([
          ES::CallNode.new(
            ES::GetLocalNode.new("one"),
            "two=",
            [ES::IntegerNode.new(10)]
          )
        ])
      }

      it "should be parsed" do
        code = "one.two = 10"
        parser.parse(code).should eq(nodes)
      end

      it "should be parsed as a real method call" do
        code = "one.two=(10)"
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

  describe "method calls" do
    it "should be parsed" do
      code = "println(\"Hello, World\")"
      nodes = ES::Nodes.new([
                ES::CallNode.new(
                  nil,
                  "println",
                  [ES::StringNode.new("Hello, World")]
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse chain calls" do
      code = "println(Sample.new.msg)"
      nodes = ES::Nodes.new([
                ES::CallNode.new(
                  nil,
                  "println",
                  [
                    ES::CallNode.new(
                      ES::CallNode.new(
                        ES::GetConstantNode.new("Sample"),
                        "new",
                        []
                      ),
                      "msg",
                      []
                    )
                  ]
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "methods" do
    it "should allow one line definitions without params" do
      code = "name do \"Name\" end"
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "name",
                  ES::MethodNode.new(
                    [],
                    ES::Nodes.new([
                      ES::StringNode.new("Name")
                    ])
                  )
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should allow one line definitions with params" do
      code = "add do |a, b| a + b end"
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "add",
                  ES::MethodNode.new(
                    ["a", "b"],
                    ES::Nodes.new([
                      ES::CallNode.new(
                        ES::GetLocalNode.new("a"),
                        "+",
                        [ES::GetLocalNode.new("b")]
                      )
                    ])
                  )
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
                  ES::MethodNode.new(
                    [],
                    ES::Nodes.new([
                      ES::StringNode.new("Name")
                    ])
                  )
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
                  ES::MethodNode.new(
                    ["a", "b"],
                    ES::Nodes.new([
                      ES::CallNode.new(
                        ES::GetLocalNode.new("a"),
                        "+",
                        [ES::GetLocalNode.new("b")]
                      )
                    ])
                  )
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
                  ES::MethodNode.new(
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
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should allow operators to be method names" do
      code = <<-CODE
      + do |add|
        "Hello, World"
      end
      CODE
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "+",
                  ES::MethodNode.new(
                    ["add"],
                    ES::Nodes.new([
                      ES::StringNode.new("Hello, World")
                    ])
                  )
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
                    ES::SetLocalNode.new(
                      "a",
                      ES::CallNode.new(
                        ES::GetLocalNode.new("a"),
                        "+",
                        [ES::IntegerNode.new(10)]
                      )
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

    it "should parse next tokens" do
      code = <<-CODE
      while 1 < 10
        next
      end
      CODE
      nodes = ES::Nodes.new([
                ES::WhileNode.new(
                  ES::CallNode.new(
                    ES::IntegerNode.new(1),
                    "<",
                    [ES::IntegerNode.new(10)]
                  ),
                  ES::Nodes.new([
                    ES::NextNode.new
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
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "test",
                  ES::MethodNode.new(
                    [],
                    ES::Nodes.new([
                      ES::ReturnNode.new(nil)
                    ])
                  )
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
      nodes = ES::Nodes.new([
                ES::DefMethodNode.new(
                  "test",
                  ES::MethodNode.new(
                    ["name"],
                    ES::Nodes.new([
                      ES::CallNode.new(
                        ES::GetInstanceVarNode.new("@names"),
                        "push",
                        [ES::GetLocalNode.new("name")]
                      ),
                      ES::ReturnNode.new(
                        ES::GetLocalNode.new("name")
                      )
                    ])
                  )
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "class definitions" do
    it "should be parsed" do
      code = "class One end"
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "One",
                  nil,
                  ES::Nodes.new([])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse with expressions" do
      code = "class One @@something = \"nothing\" end"
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "One",
                  nil,
                  ES::Nodes.new([
                    ES::SetClassVarNode.new(
                      "@@something",
                      ES::StringNode.new("nothing")
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse with multiple expressions and method definitions" do
      code = <<-CODE
      class One
        @@one = "one"

        call do
          @@one = "two"
        end
      end
      CODE
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "One",
                  nil,
                  ES::Nodes.new([
                    ES::SetClassVarNode.new(
                      "@@one",
                      ES::StringNode.new("one")
                    ),
                    ES::DefMethodNode.new(
                      "call",
                      ES::MethodNode.new(
                        [],
                        ES::Nodes.new([
                          ES::SetClassVarNode.new(
                            "@@one",
                            ES::StringNode.new("two")
                          )
                        ])
                      )
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse Greeter example" do
      code = <<-CODE
      class Greeter
        init do |@greeting| end
        greet do |name|
          "\#{@greeting} \#{name}"
        end
      end
      CODE
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "Greeter",
                  nil,
                  ES::Nodes.new([
                    ES::DefMethodNode.new(
                      "init",
                      ES::MethodNode.new(
                        ["@greeting"],
                        ES::Nodes.new([])
                      )
                    ),
                    ES::DefMethodNode.new(
                      "greet",
                      ES::MethodNode.new(
                        ["name"],
                        ES::Nodes.new([
                          ES::StringNode.new("\#{@greeting} \#{name}")
                        ])
                      )
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse inheritance" do
      code = "class One < Two end"
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "One",
                  "Two",
                  ES::Nodes.new([])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should parse inheritance with expressions" do
      code = <<-CODE
      class One < Two
        init do |one|
          @one = one
        end
      end
      CODE
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "One",
                  "Two",
                  ES::Nodes.new([
                    ES::DefMethodNode.new(
                      "init",
                      ES::MethodNode.new(
                        ["one"],
                        ES::Nodes.new([
                          ES::SetInstanceVarNode.new(
                            "@one",
                            ES::GetLocalNode.new("one")
                          )
                        ])
                      )
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
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "Test",
                  nil,
                  ES::Nodes.new([
                    ES::PropertyNode.new(["name"])
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
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "Test",
                  nil,
                  ES::Nodes.new([
                    ES::PropertyNode.new([
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
      nodes = ES::Nodes.new([
                ES::ClassNode.new(
                  "Test",
                  nil,
                  ES::Nodes.new([
                    ES::PropertyNode.new(["name"]),
                    ES::SetClassVarNode.new("@@count", ES::IntegerNode.new(0)),
                    ES::DefMethodNode.new(
                      "name",
                      ES::MethodNode.new(
                        [],
                        ES::Nodes.new([
                          ES::SetClassVarNode.new(
                            "@@count",
                            ES::CallNode.new(
                              ES::GetClassVarNode.new("@@count"),
                              "+",
                              [ES::IntegerNode.new(1)]
                            )
                          ),
                          ES::GetInstanceVarNode.new("@name")
                        ])
                      )
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end
  end

  describe "namespaces" do
    it "should be parsed" do
      code = <<-CODE
      namespace Test
        class One end
      end
      CODE
      nodes = ES::Nodes.new([
                ES::NamespaceNode.new(
                  "Test",
                  ES::Nodes.new([
                    ES::ClassNode.new(
                      "One",
                      nil,
                      ES::Nodes.new([])
                    )
                  ])
                )
              ])
      parser.parse(code).should eq(nodes)
    end

    it "should also parse namespace accessors" do
      code = <<-CODE
      namespace Test
        class One end
      end
      Test::One
      CODE
      nodes = ES::Nodes.new([
                ES::NamespaceNode.new(
                  "Test",
                  ES::Nodes.new([
                    ES::ClassNode.new(
                      "One",
                      nil,
                      ES::Nodes.new([])
                    )
                  ])
                ),
                ES::NamespaceAccessNode.new(
                  "Test",
                  ES::GetConstantNode.new("One")
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
      if a is 30
        print("It works!")
      end
      CODE
      nodes = ES::Nodes.new([
                ES::NamespaceNode.new(
                  "Things",
                  ES::Nodes.new([
                    ES::ClassNode.new(
                      "Math",
                      nil,
                      ES::Nodes.new([
                        ES::DefMethodNode.new(
                          "add",
                          ES::MethodNode.new(
                            ["a", "b"],
                            ES::Nodes.new([
                              ES::CallNode.new(
                                ES::GetLocalNode.new("a"),
                                "+",
                                [ES::GetLocalNode.new("b")]
                              )
                            ])
                          )
                        ),
                        ES::DefMethodNode.new(
                          "sub",
                          ES::MethodNode.new(
                            ["a", "b"],
                            ES::Nodes.new([
                              ES::CallNode.new(
                                ES::GetLocalNode.new("a"),
                                "-",
                                [ES::GetLocalNode.new("b")]
                              )
                            ])
                          )
                        ),
                        ES::DefMethodNode.new(
                          "div",
                          ES::MethodNode.new(
                            ["a", "b"],
                            ES::Nodes.new([
                              ES::CallNode.new(
                                ES::GetLocalNode.new("a"),
                                "/",
                                [ES::GetLocalNode.new("b")]
                              )
                            ])
                          )
                        ),
                        ES::DefMethodNode.new(
                          "mult",
                          ES::MethodNode.new(
                            ["a", "b"],
                            ES::Nodes.new([
                              ES::CallNode.new(
                                ES::GetLocalNode.new("a"),
                                "*",
                                [ES::GetLocalNode.new("b")]
                              )
                            ])
                          )
                        ),
                        ES::DefMethodNode.new(
                          "pow",
                          ES::MethodNode.new(
                            ["a", "b"],
                            ES::Nodes.new([
                              ES::CallNode.new(
                                ES::GetLocalNode.new("a"),
                                "**",
                                [ES::GetLocalNode.new("b")]
                              )
                            ])
                          )
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
                    "is",
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