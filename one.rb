$:.unshift("./lib")

require "lang/parser"

p = ES::Parser.new
p.debug

code = <<-CODE
if true
  a
  b
  c
end
CODE
nodes = p.parse(code)
puts nodes.to_s
