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

  replace_all do |pattern, replacement|
    if pattern.kind_of?(Regex)
      pattern.global = yes
      replace(pattern, replacement)
    else
      pattern = r"%pattern"g
      replace(pattern, replacement)
    end
  end

  =~ do |rx|
    if rx.kind_of?(Regex)
      match?(rx)
    else
      false
    end
  end

  match? do |rx|
    match(rx).length > 0
  end

  inspect do
    "\"" + self + "\""
  end
end