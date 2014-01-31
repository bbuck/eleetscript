class Stack < List
  top do
    last
  end

  shift do |val|
    pop
    nil
  end

  unshift do |val|
    push(val)
  end
end