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

class SpecLogger
  def error(str); end
end
