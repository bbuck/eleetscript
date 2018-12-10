# frozen_string_literal: true

require 'spec_helper'

describe EleetScript::Token do
  it 'fails to create if the type is token invalid' do
    expect(lambda {
             described_class.new(:invalid_type, nil, '', 1)
           }).to raise_error(ArgumentError, /token type/)
  end

  it 'fails to create if a negative/zero/non-numeric line number is given' do
    [0, -1, nil].each do |value|
      expect(lambda {
               described_class.new(:nil, nil, '', value)
             }).to raise_error(ArgumentError, /line number/)
    end
  end

  it 'fails to create if lexeme is not a string' do
    expect(lambda {
             described_class.new(:nil, nil, :not_a_string, 1)
           }).to raise_error(ArgumentError, /Lexeme/)
  end

  it 'successfully creates a token if all values are correct' do
    expect(lambda {
             described_class.new(:nil, nil, 'nil', 1)
           }).not_to raise_error
  end
end
