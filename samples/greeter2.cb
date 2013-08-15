class Greeter
  @@create do |greeting|
    Greeter.new(greeting)
  end
  init do |@greeting| end
  greet do |name|
    println("%@greeting, %name")
  end
end
g = Greeter.create("Hello")
g.greet("World")
