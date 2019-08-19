# frozen_string_literal: true

module EleetScript
  class Parser
    attr_reader :tokens, :root_node, :errors

    def initialize(tokens)
      @tokens = tokens
      @root_node = nil
      @parsed = false
      @errors = []
    end

    def completed?
      @parsed
    end

    def successful?
      @errors.empty?
    end

    def parse
      return root_node if completed?

      @parsed = true
    end
  end
end
