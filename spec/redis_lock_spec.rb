require 'spec_helper'
describe RedisLock do
  subject { described_class.new('my_key')}
  it 'locking behavior' do
    expect(subject.locked?).to eq false
    expect(subject.set(20)).to eq true
    expect(subject.locked?).to eq true
    expect(subject.remove).to eq true
    expect(subject.locked?).to eq false
  end

  describe 'perform' do
    it 'when there is no lock makes lock, performs block and removes lock' do
      out = subject.perform do
              {}.tap do |t|
                t[:locked?] = subject.locked?
              end
            end
      expect(out[:locked?]).to eq true
      expect(subject.locked?).to eq false
    end

    it 'when there is lock does not perform and returns nil' do
      subject.set(10)
      hello = Contextuable.new(hello: :hello)
      expect(hello).not_to receive(:hello)
      out = subject.perform do
              hello.hello
            end
      expect(out).to be nil
      expect(subject.locked?).to be true
      subject.remove
    end
  end
end
