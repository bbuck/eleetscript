class Greeter
  init do |@greeting| end
  greet do |name|
    print("%@greeting, %name")
  end
end
g = Greeter.new("Hello")
g.greet("World")
