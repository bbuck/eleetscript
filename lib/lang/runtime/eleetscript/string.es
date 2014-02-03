class String
  * do |num|
    if arguments.length > 0
      new_str = []
      str = self
      num.times -> {
        new_str < str
      }
      new_str.join("")
    else
      ""
    end
  end

  reverse do
    rev = []
    each -> { |v|
      rev.unshift(v)
    }
    rev.join("")
  end

  isnt do |value|
    not self is value
  end

  to_string do
    self
  end

  inspect do
    "\"" + self + "\""
  end
end