# frozen_string_literal: true

require_relative '../lib/eleetscript'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

def token(type, value, lexeme, line)
  EleetScript::Token.new(type, value, lexeme, line)
end

def eof(line)
  token(:eof, nil, '', line)
end

def newline(line)
  token(:newline, nil, "\n", line)
end

class SpecLogger
  def error(str); end
end

ES_GREETER = <<-GREETER
class Greeter
  property greeting

  init do |@greeting| end

  greet do |name|
    "%{@greeting}, %name!"
  end
end

en = Greeter.new("Hello")
en.greet("World")
# "Hello, World!"

es = Greeter.new("Hola")
es.greet("Mundo")
# "Hola, Mundo!"
GREETER

ES_GREETER_TOKENS = [
  token(:class, nil, 'class', 1),
  token(:identifier, 'Greeter', 'Greeter', 1),
  newline(1),
  token(:property, nil, 'property', 2),
  token(:identifier, 'greeting', 'greeting', 2),
  newline(2),
  newline(3),
  token(:identifier, 'init', 'init', 4),
  token(:do, nil, 'do', 4),
  token(:pipe, nil, '|', 4),
  token(:identifier, '@greeting', '@greeting', 4),
  token(:pipe, nil, '|', 4),
  token(:end, nil, 'end', 4),
  newline(4),
  newline(5),
  token(:identifier, 'greet', 'greet', 6),
  token(:do, nil, 'do', 6),
  token(:pipe, nil, '|', 6),
  token(:identifier, 'name', 'name', 6),
  token(:pipe, nil, '|', 6),
  newline(6),
  token(:string, "", '"%', 7),
  token(:plus, nil, '+', 7),
  token(:left_paren, nil, '(', 7),
  token(:identifier, '@greeting', '@greeting', 7),
  token(:right_paren, nil, ')', 7),
  token(:plus, nil, '+', 7),
  token(:string, ', ', ', %', 7),
  token(:plus, nil, '+', 7),
  token(:left_paren, nil, '(', 7),
  token(:identifier, 'name', 'name', 7),
  token(:right_paren, nil, ')', 7),
  token(:plus, nil, '+', 7),
  token(:string, '!', '!"', 7),
  newline(7),
  token(:end, nil, 'end', 8),
  newline(8),
  token(:end, nil, 'end', 9),
  newline(9),
  newline(10),
  token(:identifier, 'en', 'en', 11),
  token(:equal, nil, '=', 11),
  token(:identifier, 'Greeter', 'Greeter', 11),
  token(:dot, nil, '.', 11),
  token(:identifier, 'new', 'new', 11),
  token(:left_paren, nil, '(', 11),
  token(:string, 'Hello', '"Hello"', 11),
  token(:right_paren, nil, ')', 11),
  newline(11),
  token(:identifier, 'en', 'en', 12),
  token(:dot, nil, '.', 12),
  token(:identifier, 'greet', 'greet', 12),
  token(:left_paren, nil, '(', 12),
  token(:string, 'World', '"World"', 12),
  token(:right_paren, nil, ')', 12),
  newline(12),
  newline(13),
  newline(14),
  token(:identifier, 'es', 'es', 15),
  token(:equal, nil, '=', 15),
  token(:identifier, 'Greeter', 'Greeter', 15),
  token(:dot, nil, '.', 15),
  token(:identifier, 'new', 'new', 15),
  token(:left_paren, nil, '(', 15),
  token(:string, 'Hola', '"Hola"', 15),
  token(:right_paren, nil, ')', 15),
  newline(15),
  token(:identifier, 'es', 'es', 16),
  token(:dot, nil, '.', 16),
  token(:identifier, 'greet', 'greet', 16),
  token(:left_paren, nil, '(', 16),
  token(:string, 'Mundo', '"Mundo"', 16),
  token(:right_paren, nil, ')', 16),
  newline(16),
  newline(17),
  eof(18),
]
