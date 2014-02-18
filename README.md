# Introduction

EleetScript is a simple and secure scripting language designed to be hosted in
Ruby applications to add a scripting component. The desire to design a language
for this purpose instead of pursuing other options was to make a language with
no default unsafe access to the system or execution of the software unless
explicitly given.

## Status

The project is currently in an very early alpha, check below to see the status
of the different components.

- Lexer (complete (alpha))
- Parser/Grammer (complete (alpha))
- Runtime (complete (alpha))
- Interpreter (complete (alpha))
- Ruby Bridge (complete (alpha))
- Bytecode Compiler (unstarted)
- VM (for bytecode) (unstarted)

# EleetScript Language Features

## Description

EleetScript was born directly from Ruby influence, and since being a language
written in Ruby for Ruby (at least in it's current stage, future ports may
happen) it has a lot of similarities to Ruby. I've added in some minor
enhancements that I felt rounded out the full scripting aspect of the language.
Some of these enhancements were inspired by other languages such as CoffeeScript.

## Features

### Variables

EleetScript supports 5 different types of variables similar to ruby.

#### Constants

EleetScript has constant variables which start with a capital letter and can
only be assigned to once. A constant can only assigned a literal value.

```
SomeConstant = 10
CONSTANT_VALUE = "Hello, World!"
```

#### Globals

EleetScript also supports global variables which are available at all points
within a script. Globals are prefixed with a `$` character.

```
$global = List.new
$other_global = "Hello, World!"
```

#### Class

EleetScript provides class level variables that begin with the `@@` notation
like in Ruby.

```
class MyClass
  @@class_variable = "Hello, World!"
end
```

#### Instance

EleetScript, like Ruby, also provides the same instance variable notation.
Instance variables begin with `@` and are accessible for the instance of an
object.

```
@instance_var = "Hello, World!"
```

#### Local

Last but not least are the standard local variables. Local variables are only
accessible within the scope they are defined with the exception of Lambda's
(which generate a "closure" for local variables) which will be discussed later.

```
local_var = "Hello, World!"
```

### Data Types

EleetScript supports a few literal types: String, Integer, Float, Boolean and Nil.

```
"This is a string"
1 # An Integer
1.1 # A float (both Integer and Float inherit from Number)
true
yes
on  # All three of these evaluate to "true" and are instances of TrueClass
false
no
off # All three of these evaluate to "false" and are instances of FalseClass
nil # Instance of NilClass
```

EleetScript supports symbols with ruby syntax.

```
:some_symbol
```

EleetScript supports literal definitions for two types of objects, Lists and
Pairs. A List is the like a PHP `array()` or, for those not familiar with PHP,
works as both a synchronous and associative data structure. Lists can be defined
in two different ways:

```
list1 = List.new
list2 = []
```

Values can be seeded in a list literal:

```
count = [1, 2, 3]
```

Values can be accessed and set by index:

```
count = [1, 2, 3]
count[1] # => 2
count[1] = 4
println(count) # => [1, 4, 3]
```

The index is simply a key and any key can be used to access the array:

```
json = []
json["thing"] = "Something Else"
println(json["thing"]) # => Something Else
```

Pairs can be defined as a literal as well as object. A pair is essentially a key
value type of object. Since the syntatic literal definition is converted to the
object definition when parsed you can use dynamic values as keys as well.

```
p = Pair.new("one", 1)
p = "one" => 1
key = "one"
p = key => 1

p.key # => "one"
p.value # => 1
```

Pairs provide an easy, literal, method to defining associations in a list. If
you mix the literal syntax:

```
list = [1, 2, "one" => 1]
list["one"] # => 1
```

You can easily define associations.

### Decisions and Loops

Every language needs a decision structure and a looping construct.

EleetScript provides (as of right now) only an `if` construct for decision
making. The syntax for the if statement is the same as in Ruby and just like
Ruby values are evaluated "truthy," Everything but `false` (`off` and `no` included)
and `nil` will evaluate to false.

```
if true
  do_something
end

if one
  do_one
else
  do_two
end

if one
  do_one
elsif two
  do_two
else
  do_three
end
```

EleetScript only provides one formal looping construct within the language which
is a `while` loop. The theory was that a `while` loop can theoretically address
any and all looping situations that may be encountered and the number of times
that manual loops end up written in Ruby are relatively low (in my experience).

The syntax is the same as Ruby:

```
str = "Hello"
i = 0
while i < str.length
  println(str[i])
  i += 1
end
```

### Methods and Script Context

Like Ruby, EleetScript files execute as if being executed from within a class
definition. That means, for all intents and purposes, that you can picture your
scripts as if they were written with this format:

```
class Main < Object
  # Your script
end
```

This allows you to define "global" methods which are essentially methods defined
outside of an explicity class context. Methods in EleetScript resemble Ruby's
`do..end` blocks. This is the only way to define an actual method in EleetScript.

```
# Method pieces
identifier do |param, list|
  body
end
```

The identifier is usually a simple name for the method unless you want to define
a class method in which you use a class identfier:

```
@@class_identifier do |param, title|
  body
end
```

Parameter lists are defined in `|` operators.

Just like Ruby, the last value in a method is automatically returned and things
like decision structures (if statements) are also considered expressions and
return their last value.

```
# Some Method samples
add do |a, b|
  a + b
end
add(1, 2) # => 3

sub do |a, b|
  a - b
end
sub(3, 2) # => 1

mul do |a, b|
  a * b
end
mul(2, 4) # => 8

div do |a, b|
  a / b
end
div(6, 2) # => 3
```

Methods behave sightly different than they do in Ruby. EleetScript methods never
require arguments, regardless of what parameters you specify (this is the same
as Javascript). There is an arguments object in the scope of a method that is
a list of all the arguments passed to the function. This can provide some handy
features when realizing that arguments are essentially list definitons (more on
this later).

Method calls are similar to Ruby no argument calls can omit the parenthesis;
however, if you pass arguments to a method you must include parenthesis. This
helps prevent any misunderstandings on which paramters are passed to which method
call (such as this example):

```ruby
an_obj.some_method one, two, other.do three, four
```

That would be written as:

```
an_obj.some_method(one, two, other.do(three, four))
```

Which makes the intent more clear for other programmers.

#### Arguments

The `arguments` object is sometimes loved and sometimes hated in Javascript,
depending on the purpose it's used for, so it was not an easy choice to replicate
the construct with EleetScript but I felt that as a scripting language being
able to handle arguments in such a fluid was worth the cons that would inevitably
follow. Due to the way the arguments is generated (it's an instance of List) it
provides (almost for free) the concept of "splats" and named paramters.

Take for example the following:

```
something_cool do
  if arguments["user"]
    # do something with user
  elsif arguments["admin"]
    # do something with admin
  end
end

something_cool("user" => user)
something_cool("admin" => admin)
```

### Classes

Classes are similarly defined as in Ruby, aside from the difference in method
definitions. Classes can inherit a class via an extends syntax similar to Ruby
as well. Unlike Ruby, EleetScript classes do not have a "meta class" or similar
class syntax nor the feature to modify a single instance with new methods.

Simple class example:

```
class MyClass
  some_function do
    println("Hello")
  end
end
```

A more complex class example, a "Greeter"

```
class Greeter
  init do |@greeting| end
  greet do |name|
    println("%@greeting, %name!")
  end
end
```

There are a couple of undiscussed topics happening here. First is the instance
variable as a parameter notation. This works like it does in CoffeeScript, it
is the equivalent of writing the function like:

```
init do |greeting|
  @greeting = greeting
end
```

Which saves time when writing initilaizers and setter functions. Also, the `init`
function is the constructor for an object and will always be called when an object
is created.

Finally is the string interpolation. EleetScript only supports simple variable
interpolation into strings (any varaible type). To interpolate a value you begin
with a `%` and name the variable to be interpolated. If you wish to include a `%`
in the string simply escape it (`"10 \% 10"`). There are no plans to support any
complex interpolation which forces interpolation to be logicless and clean.

Like Ruby, defined classes can be reopened and added on to. These changes affect
all instances of the class that may already exist. Using this technique as well
as some EleetScript shorthand we can add some getters and setters to the `Greeter`
class.

```
class Greeter
  greeting= do |@greeting| end
  greeting do @greeting end
end
```

Just like in ruby our setter is defined as `greeting=` and can be called with some
some sugay simply by calling: `greeter.greeting = "Some new Greeting"` or, if
preferred, `greeter.greeting=("Some new Greeting")`.

Even though it's fairly painless defining getters and setters in EleetScript
it's still work and just like Ruby provides `attr_accessor` EleetScript provides
the `property` directive. If we rewrite the Greeter exampe (getter and setter
included) we get:

```
class Greeter
  property greeting
  init do |@greeting| end
  greet do |name|
    println("%@greeting, %name!")
  end
end
```

The `property` directive will create a getter and setter for the named value
given. Notice the name is not a string or symbol (which don't currently exist
in EleetScript), this is how property names are defined, in a space seperated list
follwing a property directive.

```
class MyClass
  property one two three
end
```

Inheritance works much like it does in Ruby, the inheritance directive is a `<`
followed by the name of the class to inherit from.

```
class A
end

class B < A
end
```

**NOTE** Currently, EleetScript does not support the ability to call the super
class's implmentation of a method.

## Namespaces

A Namespace is essentially a means for seperating code. This is mostly an
advanced language feature that won't find much use without the ability to import
files (which does not currenlty exist). Although the feature is in place and
usable.

```
namespace Mathematics
  class Algebra
  end

  class Calculus
  end

  class LinearAlgebra
  end
end
```

Namespaces are similar to Ruby modules and accessing their contents is the same:

```
Mathematics::LinearAlgebra.new
```

Unlike Ruby modules, they're nothing more than ways to seperate code.

## Lambdas And LeetSauce

Lambdas are to EleetScript as a Proc/Lambda is to Ruby. Lambdas behave similar
to methods (and behind the scenes they are simply methods with some scoping
magic) except they can be stored in variables and invoked when needed. They also
provide a basic closure wrapping for local variables defined in the same scope
the lambda is defined.

The goal of EleetScript was to try and provide a "one way to do it" methodology
on top of Ruby's "Do it however you want" method. So for example in Ruby you
define a method in one of two ways:

```ruby
def method_name(args)
  # body
end

define_method :method_name do |args|
  # body
end
```

Now, granted that almsot always you should use the first method apart from dynamic
method generation for DSL's and other Meta programming constructs but you can
also define Procs/Lambdas in multiple ways:

```ruby
lambda { lambda_body }
-> { lambda_body }
Proc.new do
  proc_body
end
Proc.new { proc_body }
```

In EleetScript there is one syntax for defining a method (as shown before) and
one method for defining a lambda.

```
lambda_add = -> { |a, b| a + b }

# OR

lambda_add = -> { |a, b|
  a + b
}

lambda_add.call(1, 2) # => 3
```

Methods are designed to try and integrate lambdas as final parameters just as
Ruby methods do with the way blocks are given to methods. This allows for some
interator type constructs used commonly in Ruby to translate directly to
EleetScript.

```
# Times
10.times -> { |i|
  # do something
}

[1, 2, 3].each -> { |item, index|
  # do something
}

[1, 2, 3].map -> { |item| item * 2 }
[1, 2, 3].inject(0) -> { |sum, item| sum + item }
# The above has already been defined as
[1, 2, 3].sum
```

If you want to define a method that can take a lambda, that's easy as well. They
are simply instances of the Lambda class and be any argument in the list, or if
defined trailing a function call will be the last value in the arguments List as
well as specially referenced by the `lamdba` local variable. There is also a helper
value that you can use to determine if a lamdba was given to a method: `lambda?`.

```
class MyClass
  my_lambda_method do
    if lambda?
      lambda.call(thing)
    end
  end
end
```

## Regular Expressions

Thanks to the Ruby backing EleetScript has full access to Ruby's unique "irRegular
Expression" engine. You can access Regular Expressions in the language with a
special literal syntax of by creating one with via the `Regex` class.

```
# Literal
name_rx = r"my name is (.+)"i

# Class Based
name_rx = Regex.new("my name is (.+)", "i")
```

If you wish to test a string against a regular expression you will find that
EleetScript supports the `=~` operator, which you might find more forgiving
than Rubys (`String =~ Regexp` in Ruby, either way in EleetScript).

```
rx = r"my name is (.+)"i
str = "My name is Brandon"

if str =~ rx # or str.match?(rx)
  matches = str.match(rx)
  # matches is a list of all matches, match[0] is the full match and indexes/keys
  # are matched groups - in this case matches[1] is equal to group 1.
  name = matches[1]
  println("Your name is %name")
end

rx = r"my name is (?<name>.+)"i
if str =~ rx
  matches = str.match(rx)
  # Named groups are accessed by their names
  name = matches["name"]
  println("Your name is %name")
end
```

The flags you can apply to a regular expression are similar to Ruby as well.
There is a multiline flag (`m`), ignore case flag (`i`) and global flag (`g`).
The only one not present in Ruby is the global flag which changes the scope
of the regular expression. In Ruby that is done depending on the method used with
the regular expression.

```
"ababab".replace(r"a", "c") # => "cbabab"
"ababab".replace(r"a"g, "c") # => "cbcbcb"A
```

## Reasoning for creating a new layer

There were three main driving factors into the development of EleetScript:

1. Eliminate a lot of complexity that can accompany Ruby programs (complexity in
terms of new developers). This would, theoretically, make EleetScript easier to
pick up for entry level programmers or non-programmers. This one done by forcing
certain redability contstructs and trimming out certains ways to do things.
1. Make a default secure runtime. The EleetScript Engine has no access to the
file system or process so malicious developers can't perform any bad actions
like this. The way the Engine is implemented you can easily add in access to
these features (like in the basic Engine introduction).
1. Errorless. This is something to take with a grain of salt. Originally I had
planned any error you would normally see happen in a language (like Ruby) such
as Undefined method or Undefined variable should be silently ignored and simply
given a value. This, obviously, was a really poor choice but I wanted to continue
with the premise that the scripts wouldn't "error out" if issues were encountered
and so there is a global "Errors" List where messages are placed when an error
occurs. This list can be checked to determine if certain portions of the script
are throwing errors and can be cleared before a new section to test for errors
there.

# Ruby Bridge (Engine)

What's a scripting engine without a language integration feature?

The Engine is written to try and provide near seamless interaction with the
scripting engine. The engine provides an interface for manually executing
code, calling fuctions, setting values or fetching values from withing the
EleetScript runtime instance.

There are two types of Engines that you can choose from when integrating with
EleetScript. The one you choose is dependant on how you plan on using/access the
script portions of your code. You can use the `SharedEngine` which uses a shared
memory between all instances (every instance of `SharedEngine` uses the same
core `Memory` object) and creates a unique context per instance to keep conflicts
from arising between different scripts and `SharedEngine` instances. The
`StandaloneEngine` creates a `Memory` object per instnace guaranteeing a completely
standalone context per instance for scripts.

If you only plan to use one engine in your program then the choice between shared
or standalone will, ultimately, make no difference. In large applications where
several different engines (large number of simulatneous scripts) need to be
managed then the `SharedEngine` may be more efficient due to no duplication of
EleetScript's core.

Here is an example (with comments) of doing certain things with the engine.

```ruby
require "eleetscript"

engine = ES::SharedEngine.new

new_method = <<-ES
return_nil do
  nil
end
ES

engine.execute(new_method) # runs the code
es_nil = engine.call(:new_method)

es_nil == nil # => The Engine converts Strings, Integers, Floats, true, false
# and nil to their direct ruby equivalents, no wrapper here!

add_method = <<-ES
add do |a, b|
  a + b
end
ES

engine.execute(add_method)
ten = engine.call(:add, 6, 4)
ten # => 10

ESList = engine["List"] # fetch the value of "List" from the runtime
# ESList is now a EleetToRubyWrapper that allows you to interact with it as if
# it had been defined in Ruby

list = ESList.new # Creates a new list, again EleetToRubyWrapper
list < "String" # The '<' method in EleetScript is shorthand for push and similar to << in ruby
list[0] # => "String"
list["Other Value"] = 1
list["Other Value"] # => 1

# If you want your script to access the file system, provide the ruby File class
engine["File"] = File

script = <<-ES
str = File.open("some_file.txt")
println(str)
ES

engine.execute(script)
```

The API is the same for both engine types; however, the `SharedEngine` offers
one feature unique to it. This feature, `SharedEngine#reset` allows you to start
with a new context (clearing all changes made to the local context of the instance).
**NOTE**: If you modify any core objects the modification will reflect across all
instances of `SharedEngine`.

# Name

I thought I should include this little blurb about the name. I wanted to make
it clear that this language was not named **Eleet**Script to signify that it's
better than any other language. It was named as such becuase when I first begin
fantasizing about what the language should look like and do and what language it
should run on initially I had registered a company name called "Eleet Software
Developers, L.L.C." which got it's name becuase I thought it was funny to play
with the elitist attitude the a lot of people have and of course imply that we
did good work.

Long story short, the name evolved from that and lack of a more creative name
to come to me before I released it.

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
