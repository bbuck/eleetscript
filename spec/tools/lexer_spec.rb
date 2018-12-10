# frozen_string_literal: true

require 'logger'

require 'spec_helper'

describe EleetScript::Lexer do
  RESERVED_WORDS = ['lambda?', 'lambda', 'self', 'arguments'].freeze

  KEYWORDS = ['do', 'end', 'class', 'load', 'if', 'while', 'namespace', 'else', 'elsif', 'return',
              'break', 'next', 'true', 'yes', 'on', 'false', 'no', 'off', 'nil', 'self', 'property',
              'super'].freeze

  describe 'definition' do
    subject { described_class.new('') }

    it { is_expected.to respond_to(:reserved?) }

    RESERVED_WORDS.each do |word|
      it { expect(subject.reserved?(word)).to eq(true) }
    end

    it { is_expected.to respond_to(:keyword?) }

    KEYWORDS.each do |word|
      it "expect #{word} to be a keyword" do
        expect(subject.keyword?(word)).to eq(true)
      end
    end

    it { is_expected.to respond_to(:tokenize) }
    it { is_expected.to respond_to(:done?) }
  end

  describe '#tokenize' do
    context 'behavior' do
      subject { described_class.new('') }

      context 'before called' do
        it { expect(subject.done?).to eq(false) }
      end

      context 'after called' do
        before { subject.tokenize }

        it { expect(subject.done?).to eq(true) }
      end
    end

    context 'tokenizing input' do
      let(:code) { '' }
      let(:lexer) { described_class.new(code, SpecLogger.new) }

      subject { lexer.tokens }

      before { lexer.tokenize }

      context 'operators' do
        let(:code) { '+ += - -= * *= ** **= / /= % %= < <= > >= = -> |' }

        it do
          is_expected.to contain_exactly(
            token(:plus, nil, '+', 1),
            token(:plus_equal, nil, '+=', 1),
            token(:minus, nil, '-', 1),
            token(:minus_equal, nil, '-=', 1),
            token(:star, nil, '*', 1),
            token(:star_equal, nil, '*=', 1),
            token(:star_star, nil, '**', 1),
            token(:star_star_equal, nil, '**=', 1),
            token(:forward_slash, nil, '/', 1),
            token(:forward_slash_equal, nil, '/=', 1),
            token(:percent, nil, '%', 1),
            token(:percent_equal, nil, '%=', 1),
            token(:less, nil, '<', 1),
            token(:less_equal, nil, '<=', 1),
            token(:greater, nil, '>', 1),
            token(:greater_equal, nil, '>=', 1),
            token(:equal, nil, '=', 1),
            token(:arrow, nil, '->', 1),
            token(:pipe, nil, '|', 1),
            token(:eof, nil, '', 1)
          )
        end
      end

      context 'integers' do
        let(:code) { '100 482_799 3_5_7 0b10_01 0o7_77 0xfa_ce' }

        it do
          is_expected.to contain_exactly(
            token(:integer, 100, '100', 1),
            token(:integer, 482_799, '482_799', 1),
            token(:integer, 357, '3_5_7', 1),
            token(:integer, 9, '0b10_01', 1),
            token(:integer, 511, '0o7_77', 1),
            token(:integer, 64_206, '0xfa_ce', 1),
            token(:eof, nil, '', 1)
          )
        end
      end

      context 'floats' do
        let(:code) { '0.18 6_34.08_08' }

        it do
          is_expected.to contain_exactly(
            token(:float, 0.18, '0.18', 1),
            token(:float, 634.0808, '6_34.08_08', 1),
            token(:eof, nil, '', 1)
          )
        end
      end

      context 'keywords' do
        let(:code) { EleetScript::Lexer::KEYWORDS.to_a.join(' ') }

        it do
          is_expected.to contain_exactly(
            token(:do, nil, 'do', 1),
            token(:end, nil, 'end', 1),
            token(:class, nil, 'class', 1),
            token(:load, nil, 'load', 1),
            token(:if, nil, 'if', 1),
            token(:while, nil, 'while', 1),
            token(:namespace, nil, 'namespace', 1),
            token(:else, nil, 'else', 1),
            token(:elsif, nil, 'elsif', 1),
            token(:return, nil, 'return', 1),
            token(:break, nil, 'break', 1),
            token(:next, nil, 'next', 1),
            token(:true, nil, 'true', 1),
            token(:true, nil, 'yes', 1),
            token(:true, nil, 'on', 1),
            token(:false, nil, 'false', 1),
            token(:false, nil, 'no', 1),
            token(:false, nil, 'off', 1),
            token(:nil, nil, 'nil', 1),
            token(:self, nil, 'self', 1),
            token(:property, nil, 'property', 1),
            token(:super, nil, 'super', 1),
            token(:eof, nil, '', 1)
          )
        end
      end

      context 'identifier' do
        let(:code) { 'custom Constant MixedCase withNum1 _ _start snake_case arguments' }

        it do
          is_expected.to contain_exactly(
            token(:identifier, 'custom', 'custom', 1),
            token(:identifier, 'Constant', 'Constant', 1),
            token(:identifier, 'MixedCase', 'MixedCase', 1),
            token(:identifier, 'withNum1', 'withNum1', 1),
            token(:identifier, '_', '_', 1),
            token(:identifier, '_start', '_start', 1),
            token(:identifier, 'snake_case', 'snake_case', 1),
            token(:identifier, 'arguments', 'arguments', 1),
            token(:eof, nil, '', 1)
          )
        end
      end

      context 'strings' do
        let(:code) { '"this is a string" "this string %%contains %{interpolation} %vars"' }

        it do
          is_expected.to contain_exactly(
            token(:string, 'this is a string', '"this is a string"', 1),
            token(:string, 'this string %%contains ', '"this string %%contains %', 1),
            token(:plus, nil, '+', 1),
            token(:left_paren, nil, '(', 1),
            token(:identifier, 'interpolation', 'interpolation', 1),
            token(:right_paren, nil, ')', 1),
            token(:plus, nil, '+', 1),
            token(:string, ' ', ' %', 1),
            token(:plus, nil, '+', 1),
            token(:left_paren, nil, '(', 1),
            token(:identifier, 'vars', 'vars', 1),
            token(:right_paren, nil, ')', 1),
            token(:plus, nil, '+', 1),
            token(:string, '', '"', 1),
            token(:eof, nil, '', 1)
          )
        end

        context 'interpolating expressions' do
          let(:code) { '"1 + 2 = %{1 + 2}"' }

          it do
            is_expected.to contain_exactly(
              token(:string, '1 + 2 = ', '"1 + 2 = %', 1),
              token(:plus, nil, '+', 1),
              token(:left_paren, nil, '(', 1),
              token(:integer, 1, '1', 1),
              token(:plus, nil, '+', 1),
              token(:integer, 2, '2', 1),
              token(:right_paren, nil, ')', 1),
              token(:plus, nil, '+', 1),
              token(:string, '', '"', 1),
              token(:eof, nil, '', 1)
            )
          end
        end

        context 'unterminate strings' do
          let(:code) { '"some string' }
          let(:first_error) { lexer.errors.first }

          it { expect(lexer.successful?).to eq(false) }
          it { expect(first_error).to be_kind_of(EleetScript::LexicalError) }
          it { expect(first_error.message).to match(/unexpected.*end.*string/i) }
        end

        context 'unterminated interpolation' do
          let(:code) { '"some %{interp"' }
          let(:first_error) { lexer.errors.first }

          it { expect(lexer.successful?).to eq(false) }
          it { expect(first_error).to be_kind_of(EleetScript::LexicalError) }
          it { expect(first_error.message).to match(/unexpected.*end.*interpolation/i) }
        end
      end
    end
  end
end
