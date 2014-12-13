class List
  < do |value|
    self.push(value)
  end

  + do |other|
    if other.kind_of?(List)
      self.merge!(other)
    else
      self
    end
  end

  each do
    if lambda?
      keys = self.keys
      i = 0
      while i < keys.length
        key = keys[i]
        lambda.call(self[key], key)
        i += 1
      end
    end
  end

  inject do |val, iter|
    if lambda?
      self.each -> { |item, key|
        val = lambda.call(val, item, key)
      }
    end
    val
  end

  sum do
    inject(0) -> { |sum, val|
      if val.kind_of?(Number)
        sum + val
      else
        sum
      end
    }
  end

  pairs do
    lst = []
    self.each -> { |val, key| lst < (key => val) }
    lst
  end
end