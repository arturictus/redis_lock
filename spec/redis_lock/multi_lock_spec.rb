require 'spec_helper'

describe RedisLock::MultiLock do
  let(:redis) { MockRedis.new }
  subject { described_class.new('foo', 'bar', foo: 'bar', redis: redis)}
  it 'locking behavior' do
    expect(subject.locked?).to eq false
    expect(subject.open?).to eq true
    expect(subject.set(20)).to eq true
    expect(subject.locked?).to eq true
    expect(subject.open?).to eq false
    expect(subject.remove).to eq true
    expect(subject.locked?).to eq false
  end

  it 'initialization' do
    expect(subject.keys).to eq ['foo', 'bar']
    expect(subject.locks.count).to be 2
    expect(subject.opts).to eq({ foo: 'bar', redis: redis })
    expect(subject.key).to eq("REDISLOCK::foo, REDISLOCK::bar")

    other = described_class.new('foo', 'bar')
    expect(other.keys).to eq ['foo', 'bar']
    expect(other.opts).to eq({})
    expect(other.locks.count).to be 2

    other2 = described_class.new('foo')
    expect(other2.keys).to eq ['foo']
    expect(other2.opts).to eq({})
    expect(other2.locks.count).to be 1
  end
end
