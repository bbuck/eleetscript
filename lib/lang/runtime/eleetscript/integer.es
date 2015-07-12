class Integer
  round do
    self
  end

  floor do
    self
  end

  ceil do
    self
  end

  times do |iter|
    if lambda? and iter.kind_of?(Lambda)
      i = 0
      while i < self
        iter.call(i)
        i += 1
      end
    end
  end
end