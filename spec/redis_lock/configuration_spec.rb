require 'spec_helper'
describe RedisLock::Configuration do
  describe '#redis' do
    it 'execs the block if privided' do
      c = described_class.new
      c.redis = -> { :redis }
      expect(c.redis).to eq :redis
    end

    it 'returns the setting' do
      c = described_class.new
      r = { host: :localhost }
      c.redis = r
      expect(c.redis).to be_a(Redis)
    end

    it 'raises error if not set' do
      c = described_class.new
      expect{ c.redis }.to raise_error(RedisLock::Configuration::RedisNotSet)
    end
  end
end
