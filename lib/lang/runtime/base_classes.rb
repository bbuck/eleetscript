# frozen_string_literal: true

require 'set'

module EleetScript
  class ListBase
    attr_accessor :array_value, :hash_value

    def initialize
      @array_value = []
      @hash_value = {}
    end

    def merge!(o)
      array_value.concat(o.array_value)
      hash_value.merge!(o.hash_value)
    end

    def clone
      dup
    end

    def dup
      ListBase.new.tap do |lst|
        lst.array_value = array_value.dup
        lst.hash_value = hash_value.dup
      end
    end

    def to_h
      {}.tap do |hash|
        array_value.map.with_index do |value, index|
          hash[index] = value
        end
        hash_value.map do |key, value|
          hash[key] = value
        end
      end
    end

    def clear
      array_value.clear
      hash_value.clear
    end
  end

  class ESRegex < Regexp
    attr_writer :global

    class << self
      def from_regex(regex)
        ESRegex.new(regex.source, regex.options)
      end
    end

    def initialize(pattern, desired_flags = nil)
      flag_num = 0
      if desired_flags.is_a?(String)
        flag_set = desired_flags ? Set.new(desired_flags.chars) : []
        @global = true if flag_set.include?('g')
        flag_num |= Regexp::IGNORECASE if flag_set.include?('i')
        flag_num |= Regexp::MULTILINE if flag_set.include?('m')
      else
        flag_num = desired_flags
      end
      super(pattern, flag_num)
    end

    def global?
      @global || false
    end

    def ignorecase?
      options & Regexp::IGNORECASE == Regexp::IGNORECASE
    end

    def multiline?
      options & Regexp::MULTILINE == Regexp::MULTILINE
    end

    def flags
      @flags ||= [].tap do |flags|
        flags << 'm' if multiline?
        flags << 'i' if ignorecase?
        flags << 'g' if global?
      end.join('')
    end
  end
end
