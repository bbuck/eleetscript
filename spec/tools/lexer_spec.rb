# frozen_string_literal: true

require 'logger'

require 'spec_helper'

describe EleetScript::Lexer do
  RESERVED_WORDS = %w[lambda? lambda arguments defined?].freeze

  KEYWORDS = %w[do end class load if while namespace else elsif return break next true yes on
                false no off nil self property super is isnt].freeze

  WORD_OPERATORS = %w[and or not].freeze

  SPECIAL_TOKEN_CASES = {
    'yes' => :true,
    'on'  => :true,
    'no'  => :false,
    'off' => :false,
  }.freeze

  SYMBOLS = {
    plus: '+',
    plus_equal: '+=',
    minus: '-',
    minus_equal: '-=',
    star: '*',
    star_equal: '*=',
    star_star: '**',
    star_star_equal: '**=',
    forward_slash: '/',
    forward_slash_equal: '/=',
    percent: '%',
    percent_equal: '%=',
    less: '<',
    less_equal: '<=',
    greater: '>',
    greater_equal: '>=',
    equal: '=',
    equal_tilde: '=~',
    dash_arrow: '->',
    equal_arrow: '=>',
    pipe: '|',
  }

  let(:lexical_error_klass) { EleetScript::LexicalError }

  describe 'definition' do
    subject { described_class.new('') }

    it { is_expected.to respond_to(:reserved?) }
    it { expect(described_class::RESERVED_WORDS).to contain_exactly(*RESERVED_WORDS) }

    RESERVED_WORDS.each do |word|
      it { expect(subject.reserved?(word)).to eq(true) }
    end

    it { is_expected.to respond_to(:keyword?) }
    it { expect(described_class::KEYWORDS).to contain_exactly(*KEYWORDS) }

    KEYWORDS.each do |word|
      it "expect #{word} to be a keyword" do
        expect(subject.keyword?(word)).to eq(true)
      end
    end

    it { is_expected.to respond_to(:word_operator?) }
    it { expect(described_class::WORD_OPERATORS).to contain_exactly(*WORD_OPERATORS) }

    WORD_OPERATORS.each do |word|
      it "expect #{word} to be an operator word" do
        expect(subject.word_operator?(word)).to eq(true)
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

      context 'symbols' do
        let(:code) { SYMBOLS.values.join(' ') }
        let(:tokens) do
          symbols = SYMBOLS.map { |key, value| token(key, nil, value, 1) }
          symbols << token(:eof, nil, '', 1)
        end

        it do
          is_expected.to contain_exactly(*tokens)
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
        let(:code) { KEYWORDS.to_a.join(' ') }
        let(:tokens) do
          tokens = KEYWORDS.map do |keyword|
            type = if SPECIAL_TOKEN_CASES.has_key?(keyword)
                     SPECIAL_TOKEN_CASES[keyword]
                   else
                     keyword.to_sym
                   end
            token(type, nil, keyword, 1)
          end
          tokens << token(:eof, nil, '', 1)
          tokens
        end

        it do
          is_expected.to contain_exactly(*tokens)
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
          it { expect(first_error).to be_kind_of(lexical_error_klass) }
          it { expect(first_error.message).to match(/unexpected.*end.*string/i) }
        end

        context 'unterminated interpolation' do
          let(:code) { '"some %{interp"' }
          let(:first_error) { lexer.errors.first }

          it { expect(lexer.successful?).to eq(false) }
          it { expect(first_error).to be_kind_of(lexical_error_klass) }
          it { expect(first_error.message).to match(/unexpected.*end.*interpolation/i) }
        end
      end

      context 'word operators' do
        let(:code) { 'and and= or or= not' }

        it do
          is_expected.to contain_exactly(
            token(:and, nil, 'and', 1),
            token(:and_equal, nil, 'and=', 1),
            token(:or, nil, 'or', 1),
            token(:or_equal, nil, 'or=', 1),
            token(:not, nil, 'not', 1),
            token(:eof, nil, '', 1)
          )
        end
      end
    end
  end
end
