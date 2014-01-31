class Integer
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