class Parser

token DO END CLASS LOAD IF WHILE NAMESPACE ELSE ELSIF RETURN BREAK NEXT TRUE
token YES ON FALSE NO OFF NIL SELF DEFINED PROPERTY RETURN
token CONSTANT GLOBAL CLASS_IDENTIFIER INSTANCE_IDENTIFIER IDENTIFIER
token FLOAT NUMBER STRING TERMINATOR EOF REGEX REGEX_FLAGS

prechigh
  left '.'
  left '**'
  left '*' '/' '%'
  left '+' '-'
  right '-'
  left '>' '<' '>=' '<='
  left 'is' 'isnt'
  right 'not'
  left 'and'
  left 'or'
  right '=' '*=' '/=' '%=' '+=' '-=' '**='
preclow

rule
  Program:
    /* nothing */                                          { result = Nodes.new([]) }
  | Expressions EOF                                        { result = val[0] }
  ;

  Expressions:
    Expression                                             { result = Nodes.new(val) }
  | Expressions Terminator Expression                      { result = val[0] << val[2] }
  | Expressions Terminator                                 { result = val[0] }
  | Terminator                                             { result = Nodes.new([]) }
  ;

  Terminator:
    TERMINATOR Terminator
  | TERMINATOR
  ;

  Expression:
    Literal
  | AssignmentFunction
  | Call
  | SELF                                                   { result = SelfNode.new }
  | NEXT                                                   { result = NextNode.new }
  | KeyValExpression
  | ListExpression
  | NamespaceAccess
  | Defined
  | DefMethod
  | Operation
  | SetVariable
  | GetVariable
  | Namespace
  | Class
  | If
  | While
  | Return
  | Property
  | Lambda
  | '(' Expression ')'                                     { result = val[1] }
  ;

  GetVariable:
    CONSTANT                                               { result = GetConstantNode.new(val[0]) }
  | GLOBAL                                                 { result = GetGlobalNode.new(val[0]) }
  | CLASS_IDENTIFIER                                       { result = GetClassVarNode.new(val[0]) }
  | INSTANCE_IDENTIFIER                                    { result = GetInstanceVarNode.new(val[0]) }
  | IDENTIFIER                                             { result = GetLocalNode.new(val[0]) }
  ;

  Literal:
    NUMBER                                                 { result = IntegerNode.new(val[0].to_i) }
  | FLOAT                                                  { result = FloatNode.new(val[0].to_f) }
  | STRING                                                 { result = StringNode.new(val[0]) }
  | True                                                   { result = TrueNode.new }
  | False                                                  { result = FalseNode.new }
  | NIL                                                    { result = NilNode.new }
  | Regex
  ;

  Regex:
    REGEX REGEX_FLAGS                                      { result = RegexNode.new(val[0], val[1]) }
  | REGEX                                                  { result = RegexNode.new(val[0], "") }
  ;

  ListExpression:
    List
  | Expression '[' Expression ']' '=' Expression           { result = CallNode.new(val[0], "[]=", [val[2], val[5]], nil) }
  | Expression '[' Expression ']'                          { result = CallNode.new(val[0], "[]", [val[2]], nil) }
  ;

  List:
    '[' ']'                                                { result = CallNode.new(GetConstantNode.new("List"), "new", [], nil) }
  | '[' Terminator ExpressionList ']'                      { result = CallNode.new(GetConstantNode.new("List"), "new", val[2], nil) }
  | '[' Terminator ExpressionList Terminator ']'           { result = CallNode.new(GetConstantNode.new("List"), "new", val[2], nil) }
  | '[' ExpressionList ']'                                 { result = CallNode.new(GetConstantNode.new("List"), "new", val[1], nil) }
  ;

  ExpressionList:
    Expression                                             { result = val }
  | ExpressionList ',' Terminator Expression               { result = val[0] << val[3] }
  | ExpressionList Terminator ',' Expression               { result = val[0] << val[3] }
  | ExpressionList ',' Expression                          { result = val[0] << val[2] }
  ;

  KeyValExpression:
    Expression '=>' Expression                             { result = CallNode.new(GetConstantNode.new("Pair"), "new", [val[0], val[2]], nil) }
  ;

  True:
    TRUE
  | YES
  | ON
  ;

  False:
    FALSE
  | NO
  | OFF
  ;

  AssignmentFunction
    Expression '.' IDENTIFIER '=' Expression               { result = CallNode.new(val[0], "#{val[2]}=", [val[4]], nil) }
  ;

  Call:
    IDENTIFIER Lambda                                      { result = CallNode.new(nil, val[0], [], val[1]) }
  | IDENTIFIER Arguments Lambda                            { result = CallNode.new(nil, val[0], val[1], val[2]) }
  | IDENTIFIER Arguments                                   { result = CallNode.new(nil, val[0], val[1], nil) }
  | Expression '.' IDENTIFIER Arguments Lambda             { result = CallNode.new(val[0], val[2], val[3], val[4]) }
  | Expression '.' IDENTIFIER Arguments                    { result = CallNode.new(val[0], val[2], val[3], nil) }
  | Expression '.' IDENTIFIER Lambda                       { result = CallNode.new(val[0], val[2], [], val[3]) }
  | Expression '.' IDENTIFIER                              { result = CallNode.new(val[0], val[2], [], nil) }
  | Expression '.' Operator Arguments                      { result = CallNode.new(val[0], val[2], val[3], nil) }
  | Expression '.' 'not'                                   { result = CallNode.new(val[0], val[2], [], nil) }
  ;

  Arguments:
    '(' ')'                                                { result = [] }
  | '(' ArgList ')'                                        { result = val[1] }
  ;

  ArgList:
    Expression                                             { result = val }
  | ArgList ',' Expression                                 { result = val[0] << val[2] }
  ;

  Lambda:
   '->' '{' Parameters Expressions '}'                     { result = LambdaNode.new(val[2], val[3]) }
  ;

  Defined:
    DEFINED '(' GetVariable ')'                            { result = DefinedNode.new(val[2]) }
  ;

  NamespaceAccess:
    CONSTANT '::' Expression                               { result = NamespaceAccessNode.new(val[0], val[2]) }
  | '::' Expression                                        { result = NamespaceAccessNode.new(nil, val[1]) }
  ;

  Operation:
    Expression '+' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '-' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | '-' Expression                                         { result = CallNode.new(val[1], "negate", [], nil) }
  | Expression '*' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '**' Expression                             { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '/' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '%' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '>' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '>=' Expression                             { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '<' Expression                              { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '<=' Expression                             { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | OperatorAssignment
  | 'not' Expression                                       { result = CallNode.new(val[1], val[0], [], nil) }
  | Expression 'and' Expression                            { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression 'or' Expression                             { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression 'is' Expression                             { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression 'isnt' Expression                           { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  | Expression '=~' Expression                             { result = CallNode.new(val[0], val[1], [val[2]], nil) }
  ;

  OperatorAssignment:
    CONSTANT '+=' Expression                               { result = SetConstantNode.new(val[0], CallNode.new(GetConstantNode.new(val[0]), "+", [val[2]], nil)) }
  | GLOBAL '+=' Expression                                 { result = SetGlobalNode.new(val[0], CallNode.new(GetGlobalNode.new(val[0]), "+", [val[2]], nil)) }
  | CLASS_IDENTIFIER '+=' Expression                       { result = SetClassVarNode.new(val[0], CallNode.new(GetClassVarNode.new(val[0]), "+", [val[2]], nil)) }
  | INSTANCE_IDENTIFIER '+=' Expression                    { result = SetInstanceVarNode.new(val[0], CallNode.new(GetInstanceVarNode.new(val[0]), "+", [val[2]], nil)) }
  | IDENTIFIER '+=' Expression                             { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), "+", [val[2]], nil)) }
  | CONSTANT '-=' Expression                               { result = SetConstantNode.new(val[0], CallNode.new(GetConstantNode.new(val[0]), "-", [val[2]], nil)) }
  | GLOBAL '-=' Expression                                 { result = SetGlobalNode.new(val[0], CallNode.new(GetGlobalNode.new(val[0]), "-", [val[2]], nil)) }
  | CLASS_IDENTIFIER '-=' Expression                       { result = SetClassVarNode.new(val[0], CallNode.new(GetClassVarNode.new(val[0]), "-", [val[2]], nil)) }
  | INSTANCE_IDENTIFIER '-=' Expression                    { result = SetInstanceVarNode.new(val[0], CallNode.new(GetInstanceVarNode.new(val[0]), "-", [val[2]], nil)) }
  | IDENTIFIER '-=' Expression                             { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), "-", [val[2]], nil)) }
  | CONSTANT '*=' Expression                               { result = SetConstantNode.new(val[0], CallNode.new(GetConstantNode.new(val[0]), "*", [val[2]], nil)) }
  | GLOBAL '*=' Expression                                 { result = SetGlobalNode.new(val[0], CallNode.new(GetGlobalNode.new(val[0]), "*", [val[2]], nil)) }
  | CLASS_IDENTIFIER '*=' Expression                       { result = SetClassVarNode.new(val[0], CallNode.new(GetClassVarNode.new(val[0]), "*", [val[2]], nil)) }
  | INSTANCE_IDENTIFIER '*=' Expression                    { result = SetInstanceVarNode.new(val[0], CallNode.new(GetInstanceVarNode.new(val[0]), "*", [val[2]], nil)) }
  | IDENTIFIER '*=' Expression                             { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), "*", [val[2]], nil)) }
  | CONSTANT '/=' Expression                               { result = SetConstantNode.new(val[0], CallNode.new(GetConstantNode.new(val[0]), "/", [val[2]], nil)) }
  | GLOBAL '/=' Expression                                 { result = SetGlobalNode.new(val[0], CallNode.new(GetGlobalNode.new(val[0]), "/", [val[2]], nil)) }
  | CLASS_IDENTIFIER '/=' Expression                       { result = SetClassVarNode.new(val[0], CallNode.new(GetClassVarNode.new(val[0]), "/", [val[2]], nil)) }
  | INSTANCE_IDENTIFIER '/=' Expression                    { result = SetInstanceVarNode.new(val[0], CallNode.new(GetInstanceVarNode.new(val[0]), "/", [val[2]], nil)) }
  | IDENTIFIER '/=' Expression                             { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), "/", [val[2]], nil)) }
  | CONSTANT '%=' Expression                               { result = SetConstantNode.new(val[0], CallNode.new(GetConstantNode.new(val[0]), "%", [val[2]], nil)) }
  | GLOBAL '%=' Expression                                 { result = SetGlobalNode.new(val[0], CallNode.new(GetGlobalNode.new(val[0]), "%", [val[2]], nil)) }
  | CLASS_IDENTIFIER '%=' Expression                       { result = SetClassVarNode.new(val[0], CallNode.new(GetClassVarNode.new(val[0]), "%", [val[2]], nil)) }
  | INSTANCE_IDENTIFIER '%=' Expression                    { result = SetInstanceVarNode.new(val[0], CallNode.new(GetInstanceVarNode.new(val[0]), "%", [val[2]], nil)) }
  | IDENTIFIER '%=' Expression                             { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), "%", [val[2]], nil)) }
  | CONSTANT '**=' Expression                              { result = SetConstantNode.new(val[0], CallNode.new(GetConstantNode.new(val[0]), "**", [val[2]], nil)) }
  | GLOBAL '**=' Expression                                { result = SetGlobalNode.new(val[0], CallNode.new(GetGlobalNode.new(val[0]), "**", [val[2]], nil)) }
  | CLASS_IDENTIFIER '**=' Expression                      { result = SetClassVarNode.new(val[0], CallNode.new(GetClassVarNode.new(val[0]), "**", [val[2]], nil)) }
  | INSTANCE_IDENTIFIER '**=' Expression                   { result = SetInstanceVarNode.new(val[0], CallNode.new(GetInstanceVarNode.new(val[0]), "**", [val[2]], nil)) }
  | IDENTIFIER '**=' Expression                            { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), "**", [val[2]], nil)) }
  | IDENTIFIER '.=' IDENTIFIER Arguments Lambda            { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), val[2], val[3], val[4])) }
  | IDENTIFIER '.=' IDENTIFIER Arguments                   { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), val[2], val[3], nil)) }
  | IDENTIFIER '.=' IDENTIFIER                             { result = SetLocalNode.new(val[0], CallNode.new(GetLocalNode.new(val[0]), val[2], [], nil)) }
  ;

  SetVariable:
    CONSTANT '=' Literal                                   { result = SetConstantNode.new(val[0], val[2]) }
  | GLOBAL '=' Expression                                  { result = SetGlobalNode.new(val[0], val[2]) }
  | CLASS_IDENTIFIER '=' Expression                        { result = SetClassVarNode.new(val[0], val[2]) }
  | INSTANCE_IDENTIFIER '=' Expression                     { result = SetInstanceVarNode.new(val[0], val[2]) }
  | IDENTIFIER '=' Expression                              { result = SetLocalNode.new(val[0], val[2]) }
  ;

  DefMethod:
    IDENTIFIER MethodBlock                                 { result = DefMethodNode.new(val[0], val[1]) }
  | CLASS_IDENTIFIER MethodBlock                           { result = DefMethodNode.new(val[0], val[1]) }
  | Operator MethodBlock                                   { result = DefMethodNode.new(val[0], val[1]) }
  | '[' ']' '=' MethodBlock                                { result = DefMethodNode.new("[]=", val[3]) }
  | '[' ']' MethodBlock                                    { result = DefMethodNode.new("[]", val[2]) }
  ;

  MethodBlock:
    DO Parameters Expressions END                          { result = MethodNode.new(val[1], val[2]) }
  | DO Parameters END                                      { result = MethodNode.new(val[1], Nodes.new([])) }
  ;

  Operator:
    '+'
  | '-'
  | '*'
  | '/'
  | '%'
  | '**'
  | '[]'
  | '[]='
  | 'and'
  | 'or'
  | 'not'
  | 'is'
  | 'isnt'
  | '>'
  | '>='
  | '<='
  | '<'
  | '=~'
  ;

  Parameters:
    /* nothing */                                          { result = [] }
  | Terminator                                             { result = [] }
  | '|' ParamList '|' Terminator                           { result = val[1] }
  | '|' ParamList '|'                                      { result = val[1] }
  ;

  ParamList:
    Parameter                                              { result = val }
  | ParamList ',' Parameter                                { result = val[0] << val[2] }
  ;

  Parameter:
    IDENTIFIER                                             { result = val[0] }
  | INSTANCE_IDENTIFIER                                    { result = val[0] }
  | CLASS_IDENTIFIER                                       { result = val[0] }
  ;

  Namespace:
    NAMESPACE CONSTANT Expressions END                     { result = NamespaceNode.new(val[1], val[2]) }
  | NAMESPACE CONSTANT Terminator Expressions END          { result = NamespaceNode.new(val[1], val[3]) }
  | NAMESPACE CONSTANT END                                 { result = NamespaceNode.new(val[1], Nodes.new([])) }
  ;

  Class:
    CLASS CONSTANT Expressions END                         { result = ClassNode.new(val[1], nil, val[2]) }
  | CLASS CONSTANT Terminator Expressions END              { result = ClassNode.new(val[1], nil, val[3]) }
  | CLASS CONSTANT END                                     { result = ClassNode.new(val[1], nil, Nodes.new([])) }
  | CLASS CONSTANT Terminator END                          { result = ClassNode.new(val[1], nil, Nodes.new([])) }
  | CLASS CONSTANT '<' CONSTANT Expressions END            { result = ClassNode.new(val[1], val[3], val[4]) }
  | CLASS CONSTANT '<' CONSTANT Terminator Expressions END { result = ClassNode.new(val[1], val[3], val[5]) }
  | CLASS CONSTANT '<' CONSTANT END                        { result = ClassNode.new(val[1], val[3], Nodes.new([])) }
  | CLASS CONSTANT '<' CONSTANT Terminator END             { result = ClassNode.new(val[1], val[3], Nodes.new([])) }
  ;

  If:
    IF Expression Terminator Expressions END               { result = IfNode.new(val[1], val[3], nil) }
  | IF Expression Terminator Expressions Else              { result = IfNode.new(val[1], val[3], val[4]) }
  ;

  Else:
    ELSE Terminator Expressions Terminator END             { result = ElseNode.new(val[2]) }
  | ELSE Terminator Expressions END                        { result = ElseNode.new(val[2]) }
  | ElseIf
  ;

  ElseIf:
    ELSIF Expression Terminator Expressions END            { result = ElseNode.new(IfNode.new(val[1], val[3], nil)) }
  | ELSIF Expression Terminator Expressions Else           { result = ElseNode.new(IfNode.new(val[1], val[3], val[4])) }
  ;

  While:
    WHILE Expression Terminator Expressions END            { result = WhileNode.new(val[1], val[3]) }
  ;

  Return:
    RETURN Expression                                      { result = ReturnNode.new(val[1]) }
  | RETURN                                                 { result = ReturnNode.new(nil) }
  ;

  Property:
    PROPERTY IDENTIFIER                                    { result = PropertyNode.new([val[1]]) }
  | PROPERTY PropertyList                                  { result = PropertyNode.new(val[1]) }
  ;

  PropertyList:
    IDENTIFIER IDENTIFIER                                  { result = [val[0], val[1]] }
  | PropertyList IDENTIFIER                                { result = val[0] << val[1] }
  ;

end

---- header
require "lang/lexer"
require "lang/nodes"

module EleetScript

---- inner
def debug
  @yydebug = true
end

def parse(code, show_tokens = false)
  debug
  @tokens = Lexer.new.tokenize(code)
  p @tokens if show_tokens
  do_parse
end

def next_token
  @tokens.shift
end

---- footer
end # module EleetScript