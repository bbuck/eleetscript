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

  push do |val|
    unshift(val)
  end
end