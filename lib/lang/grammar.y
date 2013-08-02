class Parser

token DO END CLASS LOAD IF WHILE NAMESPACE ELSE ELSIF RETURN BREAK NEXT TRUE
token YES ON FALSE NO OFF NIL SELF DEFINED PROPERTY RETURN
token CONSTANT GLOBAL CLASS_IDENTIFIER INSTANCE_IDENTIFIER IDENTIFIER
token FLOAT NUMBER STRING TERMINATOR EOF

prechigh
  left '.'
  left '**'
  left '*' '/' '%'
  left '+' '-'
  left '>' '<' '>=' '<='
  left '==' '!='
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
  | Expressions TERMINATOR Expression                      { result = val[0] << val[2] }
  | Expressions TERMINATOR                                 { result = val[0] }
  | TERMINATOR                                             { result = Nodes.new([]) }
  ;

  Expression:
    Literal
  | AssignmentFunction
  | Call
  | SELF                                                   { result = SelfNode.new }
  | NEXT                                                   { result = NextNode.new }
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
  | NamespaceAccess
  | '(' Expression ')'                                     { result = val[1] }
  ;

  Literal:
    NUMBER                                                 { result = IntegerNode.new(val[0].to_i) }
  | FLOAT                                                  { result = FloatNode.new(val[0].to_f) }
  | STRING                                                 { result = StringNode.new(val[0]) }
  | True                                                   { result = TrueNode.new }
  | False                                                  { result = FalseNode.new }
  | NIL                                                    { result = NilNode.new }
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
    Expression '.' IDENTIFIER '=' Expression               { result = CallNode.new(val[0], "#{val[2]}=", [val[4]]) }
  ;

  Call:
    IDENTIFIER Arguments                                   { result = CallNode.new(nil, val[0], val[1]) }
  | Expression '.' IDENTIFIER Arguments                    { result = CallNode.new(val[0], val[2], val[3]) }
  | Expression '.' IDENTIFIER                              { result = CallNode.new(val[0], val[2], []) }
  | Expression '.' Operator Arguments                      { result = CallNode.new(val[0], val[2], val[3]) }
  | Expression '.' 'not'                                   { result = CallNode.new(val[0], val[2], []) }
  ;

  Arguments:
    '(' ')'                                                { result = [] }
  | '(' ArgList ')'                                        { result = val[1] }
  ;

  ArgList:
    Expression                                             { result = val }
  | ArgList ',' Expression                                 { result = val[0] << val[2] }
  ;

  Defined:
    DEFINED '(' GetVariable ')'                            { result = DefinedNode.new(val[2]) }
  ;

  NamespaceAccess:
    CONSTANT '::' IDENTIFIER                               { result = NamespaceAccessNode.new(val[0], val[2]) }
  | CONSTANT '::' CONSTANT                                 { result = NamespaceAccessNode.new(val[0], GetConstantNode.new(val[2])) }
  | CONSTANT '::' Expression                               { result = NamespaceAccessNode.new(val[0], val[2]) }
  | '::' IDENTIFIER                                        { result = NamespaceAccessNode.new(nil, val[1]) }
  | '::' CONSTANT                                          { result = NamespaceAccessNode.new(nil, GetConstantNode.new(val[1])) }
  | '::' Expression                                        { result = NamespaceAccessNode.new(nil, val[1]) }
  ;

  Operation:
    Expression '+' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '-' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '*' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '**' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '/' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '%' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '>' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '>=' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '<' Expression                              { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '<=' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | OperatorAssignment
  | 'not' Expression                                       { result = CallNode.new(val[1], val[0], []) }
  | Expression 'and' Expression                            { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression 'or' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '==' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression 'is' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '!=' Expression                             { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression 'isnt' Expression                           { result = CallNode.new(val[0], val[1], [val[2]]) }
  ;

  OperatorAssignment:
    GetVariable '+=' Expression                            { result = CallNode.new(val[0], val[1], [val[2]]) }
  | GetVariable '-=' Expression                            { result = CallNode.new(val[0], val[1], [val[2]]) }
  | GetVariable '*=' Expression                            { result = CallNode.new(val[0], val[1], [val[2]]) }
  | GetVariable '/=' Expression                            { result = CallNode.new(val[0], val[1], [val[2]]) }
  | GetVariable '%=' Expression                            { result = CallNode.new(val[0], val[1], [val[2]]) }
  | GetVariable '**=' Expression                           { result = CallNode.new(val[0], val[1], [val[2]]) }
  ;

  GetVariable:
    CONSTANT                                               { result = GetConstantNode.new(val[0]) }
  | GLOBAL                                                 { result = GetGlobalNode.new(val[0]) }
  | CLASS_IDENTIFIER                                       { result = GetClassVarNode.new(val[0]) }
  | INSTANCE_IDENTIFIER                                    { result = GetInstanceVarNode.new(val[0]) }
  | IDENTIFIER                                             { result = GetLocalNode.new(val[0]) }
  ;

  SetVariable:
    CONSTANT '=' Literal                                   { result = SetConstantNode.new(val[0], val[2]) }
  | GLOBAL '=' Expression                                  { result = SetGlobalNode.new(val[0], val[2]) }
  | CLASS_IDENTIFIER '=' Expression                        { result = SetClassVarNode.new(val[0], val[2]) }
  | INSTANCE_IDENTIFIER '=' Expression                     { result = SetInstanceVarNode.new(val[0], val[2]) }
  | IDENTIFIER '=' Expression                              { result = SetLocalNode.new(val[0], val[2]) }
  ;

  DefMethod:
    IDENTIFIER DO Parameters Expressions END               { result = DefMethodNode.new(val[0], val[2], val[3]) }
  | IDENTIFIER DO Parameters END                           { result = DefMethodNode.new(val[0], val[2], Nodes.new([])) }
  | CLASS_IDENTIFIER DO Parameters Expressions END         { result = DefMethodNode.new(val[0], val[2], val[3]) }
  | CLASS_IDENTIFIER DO Parameters END                     { result = DefMethodNode.new(val[0], val[2], Nodes.new([])) }
  | Operator DO Parameters Expressions END                 { result = DefMethodNode.new(val[0], val[2], val[3]) }
  | Operator DO Parameters END                             { result = DefMethodNode.new(val[0], val[2], Nodes.new([])) }
  ;

  Operator:
    '+'
  | '+='
  | '-'
  | '-='
  | '*'
  | '*='
  | '/'
  | '/='
  | '%'
  | '%='
  | '**'
  | '**='
  | '[]'
  | '[]='
  | 'and'
  | 'or'
  | 'not'
  | 'is'
  | 'isnt'
  | '=='
  | '!='
  | '>'
  | '>='
  | '<='
  | '<'
  ;

  Parameters:
    /* nothing */                                          { result = [] }
  | TERMINATOR                                             { result = [] }
  | '|' ParamList '|' TERMINATOR                           { result = val[1] }
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
  | NAMESPACE CONSTANT TERMINATOR Expressions END          { result = NamespaceNode.new(val[1], val[3]) }
  | NAMESPACE CONSTANT END                                 { result = NamespaceNode.new(val[1], Nodes.new([])) }
  ;

  Class:
    CLASS CONSTANT Expressions END                         { result = ClassNode.new(val[1], nil, val[2]) }
  | CLASS CONSTANT TERMINATOR Expressions END              { result = ClassNode.new(val[1], nil, val[3]) }
  | CLASS CONSTANT END                                     { result = ClassNode.new(val[1], nil, Nodes.new([])) }
  | CLASS CONSTANT TERMINATOR END                          { result = ClassNode.new(val[1], nil, Nodes.new([])) }
  | CLASS CONSTANT '<' CONSTANT Expressions END            { result = ClassNode.new(val[1], val[3], val[4]) }
  | CLASS CONSTANT '<' CONSTANT TERMINATOR Expressions END { result = ClassNode.new(val[1], val[3], val[5]) }
  | CLASS CONSTANT '<' CONSTANT END                        { result = ClassNode.new(val[1], val[3], Nodes.new([])) }
  | CLASS CONSTANT '<' CONSTANT TERMINATOR END             { result = ClassNode.new(val[1], val[3], Nodes.new([])) }
  ;

  If:
    IF Expression TERMINATOR Expressions END               { result = IfNode.new(val[1], val[3], nil) }
  | IF Expression TERMINATOR Expressions Else              { result = IfNode.new(val[1], val[3], val[4]) }
  ;

  Else:
    ELSE TERMINATOR Expression TERMINATOR END              { result = ElseNode.new(val[2]) }
  | ELSE TERMINATOR Expressions END                        { result = ElseNode.new(val[2]) }
  | ElseIf
  ;

  ElseIf:
    ELSIF Expression TERMINATOR Expressions END            { result = ElseNode.new(IfNode.new(val[1], val[3], nil)) }
  | ELSIF Expression TERMINATOR Expressions Else           { result = ElseNode.new(IfNode.new(val[1], val[3], val[4])) }
  ;

  While:
    WHILE Expression TERMINATOR Expressions END            { result = WhileNode.new(val[1], val[3]) }
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

module Cuby

---- inner
def debug
  @yydebug = true
end

def parse(code, show_tokens = false)
  @tokens = Lexer.new.tokenize(code)
  p @tokens if show_tokens
  do_parse
end

def next_token
  @tokens.shift
end

---- footer
end # module Cuby