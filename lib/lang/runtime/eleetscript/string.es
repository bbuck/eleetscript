class String
  * do |num|
    str = ""
    if num.kind_of?(Number) and num > 0
      i = 0
      while i < num
        i += 1
        str += self
      end
      return str
    else
      self
    end
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