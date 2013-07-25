$consant = "constants start with $"
@var = "variables start with @"
@scoped = "scoped to global object here, like in JS"

class Sample
  @var_here = "scoped to class Sample, class variable
  method_name do |args, lik, ruby, blocks|
    # Here methods are defined
    @here = "variables are scoped to instances of Sample
  end
end

# More info

class Sample # classes like in ruby can be reopened later
  # Just like rubies attr_accessor except no need for symbols
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
  property name, greeting

  construct do |@name, @greeting|
  end

  greet do
    println("#{greeting} #{name}") # Parenthesis required for functions
  end
end

@greeter = Greeter.new("Hello", "World")
@greeter.greet # Parenthesis not required when no parameters are given
