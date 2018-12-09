require 'engine/engine'

describe 'EleetToRubyWrapper' do
  let(:engine) { EleetScript::SharedEngine.new }

  describe '#to_h' do
    context 'for lists' do
      context 'with no pairs' do
        subject { engine.execute('[1, 2, 3]').to_h }

        it 'is a Hash object' do
          expect(subject.class).to eq(Hash)
        end

        it 'associates index to value' do
          expect(subject).to include(0 => 1, 1 => 2, 2 => 3)
        end
      end

      context 'with pairs' do
        subject { engine.execute('[:one => 1, :two => 2, :three => 3]').to_h }

        it 'is a Hash object' do
          expect(subject.class).to eq(Hash)
        end

        it 'associates key to value' do
          expect(subject).to include(one: 1, two: 2, three: 3)
        end
      end

      context 'with array and hash parts' do
        subject { engine.execute('[1, :one => 1]').to_h }

        it 'is a Hash object' do
          expect(subject.class).to eq(Hash)
        end

        it 'associates key to value' do
          expect(subject).to include(0 => 1, :one => 1)
        end
      end
    end

    context 'when to_list is defined' do
      subject { engine.execute('Que.new(1, 2, 3)') }
      let(:expected) { {0 => 1, 1 => 2, 2 => 3} }

      it 'calls Enumerable#to_list and returns a ruby hash' do
        expect(subject.to_h).to include(expected)
      end
    end

    context 'when to_list is not defined' do
      subject { engine.execute('Random') }

      it 'returns an empty Hash' do
        expect(subject.to_h).to eq({})
      end
    end
  end
end
