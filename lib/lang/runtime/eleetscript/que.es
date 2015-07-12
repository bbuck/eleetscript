class Que < List
  front do
    first
  end

  back do
    last
  end

  pop do
    shift
  end

  unshift do |val|
    push(val)
  end
end