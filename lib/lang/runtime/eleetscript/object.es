class Object
  @@kind_of? do
    no
  end

  @@no_method do
    cls_name = class_name
    Errors < "Undefined method \"%name\" called on %cls_name."
    nil
  end

  @@inspect do
    class_name
  end

  @@println do |msg|
    IO.println(msg)
  end

  @@print do |msg|
    IO.print(msg)
  end

  to_string do
    class_name
  end

  println do |msg|
    IO.println(msg)
  end

  print do |msg|
    IO.print(msg)
  end

  inspect do
    to_string
  end

  no_method do |name|
    cls_name = class_name
    Errors < "Undefined method \"%name\" called on instance of %cls_name."
    nil
  end

  not do
    self
  end
end