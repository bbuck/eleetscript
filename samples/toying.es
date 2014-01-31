CONSTANT = "have standard syntax"
$globals = "Start with a $, much like in Ruby and can be accessed anywhere"
@@class = "Scopped to class"
@instance = "Scoped to instance"
local = "Doubles as local method call or local variable if no method is defined"

class Sample
  @@var_here = "class variable like in ruby"
  method_name do |args, like, ruby, blocks| # method definition like ruby blocks
    @here = "variables are scoped to instances of Sample"
  end
end

# More info

class Sample # classes like in ruby can be reopened later
  # Just like ruby's attr_accessor except no need for symbols
  property name

  init do |@name| # Like ruby's initialize function
    # Like in CoffeeScript this will assign the first argument to the instances @name variable
  end
end

namespace Something # Like Ruby's module
  class Else
  end
end

Something::Else # Access Else class in Something namespace

# Sample Hello World

class Greeter
  property name greeting

  # Bodyless functions can be defined on one line
  init do |@greeting, @name| end

  greet do
    println("%@greeting, %@name!") # Parenthesis required for functions
  end
end

# Methods defined outside of class or namespace belong to Object
global_method do |fun|
  have(fun)
end
# Call the above method with:
#   global_method(fun)
#   self.global_method(fun)
#   Object.new.global_method(fun)
#

greeter = Greeter.new("Hello", "World")
greeter.greet # Parenthesis not required when no arguments are given
