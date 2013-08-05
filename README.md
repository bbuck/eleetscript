# Introduction

Cuby is a simple and secure scripting language desgined to be hosted in
ruby applications to add a scripting component. The desire to design a language
for this purpose instead of pursuing other options is to make a language with
no default unsafe access to the system or execution of the software unless
explicitly given.

## Status

The project is currently in an very early alpha, the language is incomplete and
as of the current state the lexer is the only thing completed.

- Lexer (complete)
- Parser/Grammer (complete)
- Runtime (complete)
- Interpreter (started)
- Bytecode Compiler
- VM (for bytecode)

## Proposed Examples

Cuby is built on top of the ruby language and so ruby syntax is borrowed
heavily as well as some minor inspiration from [CoffeeScript](coffeescript.org).

```cuby
# Math sample
class Math
  @@add do |a, b| # The @@ is a class identifier, making @@add a class method
    # Method syntax resembles that of ruby block definitions
    a + b # last item implicitly returned
  end

  @@div do |a, b|
    if b == 0
      return 0 # Explicit returns work as well
    end
    a / b
  end

  @@pi do
    3.14
  end
end

Math.add(10, 20) # method calls with params require parenthesis
# => 30
Math.pi # parameterless calls do not require parenthesis
# => 3.14
```

```cuby
# Greeter sample
class Greeter
  property greeting # similar to ruby's attr_accessor, defines 'greeting' and 'greeting=(value)'

  init do |@greeting| end # from CoffeeScript, assigns @greeting to value of first argument

  greet do |name|
    print("%greeting, %name") # simple variable interpolation with %var_name, complex interpolation of expressions not supported
  end
end

greeter = Greeter.new("Hello")
greeter.greet("World")
# => "Hello, World"
```

# Thanks

Thanks to Nick for the name 'Cuby'

# License

[MIT](http://opensource.org/licenses/MIT)

Copyright (c) 2013 Brandon Buck

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
