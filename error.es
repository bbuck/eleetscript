class Sample # classes like in ruby can be reopened later
  # Just like ruby's attr_accessor except no need for symbols
  property name

  init do |@name| # Like ruby's initialize function
    # Like in CoffeeScript this will assign the first argument to the instances @name variable
  end
end

s = Sample.new("hello")
println(s.name)