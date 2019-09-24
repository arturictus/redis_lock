require 'spec_helper'
describe RedisLock do
  let(:redis) { MockRedis.new }
  subject { described_class.new('my_key', redis: redis)}
  it 'locking behavior' do
    expect(subject.locked?).to eq false
    expect(subject.open?).to eq true
    expect(subject.set(20)).to eq true
    expect(subject.locked?).to eq true
    expect(subject.open?).to eq false
    expect(subject.remove).to eq true
    expect(subject.locked?).to eq false
  end

  describe "class helpers" do
    it "semaphore" do
      hello = 1
      before_t = Time.now.to_i
      after_t = Time.now.to_i
      described_class.semaphore("hello_semaphore") do
        after_t = Time.now.to_i
        hello = 2
      end
      expect(hello).to eq(2)
      expect(after_t - before_t).to eq(0)
    end
  end

  describe 'semaphore' do
    it "waits until lock is released to perform de block" do
      lock = described_class.new('semaphore_key')
      hello = 1
      before_t = Time.now.to_i
      lock.set(2)
      after_t = Time.now.to_i
      lock.semaphore do
        after_t = Time.now.to_i
        hello = 2
      end
      expect(hello).to eq(2)
      expect(after_t - before_t).to be_between(1, 3) # expected 2
    end

    it "long time waiting" do
      lock = described_class.new('semaphore_key')
      hello = 1
      before_t = Time.now.to_i
      lock.set(10)
      after_t = Time.now.to_i
      lock.semaphore do
        after_t = Time.now.to_i
        hello = 2
      end
      expect(hello).to eq(2)
      expect(after_t - before_t).to be_between(9, 11) #expected 10
    end
  end

  describe '::multi_semaphore' do
    it "waits until lock is released to perform de block" do
      hello = 1
      before_t = Time.now.to_i
      l_1 = RedisLock.new('semaphore_key', redis: redis)
      l_2 = RedisLock.new('another_key', redis: redis)
      after_t = Time.now.to_i
      l_1.set(2)
      out = described_class.semaphore('semaphore_key', 'another_key', redis: redis) do
              expect(l_1.locked?).to be true
              expect(l_2.locked?).to be true
              after_t = Time.now.to_i
              hello = 2
              'hello'
            end
      expect(l_1.locked?).to be false
      expect(l_2.locked?).to be false
      expect(out).to eq('hello')
      expect(hello).to eq(2)
      expect(after_t - before_t).to be_between(1, 3) # expected 2
    end
  end

  describe 'if_open' do
    it 'executes the block when no lock is set' do
      out = subject.if_open do |lock|
              subject.locked?
            end
      expect(out).to be false
      expect(subject.locked?).to eq false
    end

    it 'can access to lock and lock it after' do
      locked = nil
      subject.if_open do |lock|
        locked = subject.locked?
        lock.set(20)
      end
      expect(locked).to be false
      expect(subject.locked?).to eq true
    end

    it 'when there is lock does not perform and returns nil' do
      subject.set(10)
      hello = Dystruct.new(hello: :hello)
      expect(hello).not_to receive(:hello)
      out = subject.if_open do
              hello.hello
            end
      expect(out).to be :locked
      expect(subject.locked?).to be true
      subject.remove
    end
    it 'when there is NO lock does perform and returns what block returns' do
      hello = Dystruct.new(hello: :hello)
      expect(hello).to receive(:hello).once.and_call_original
      out = subject.if_open do
              hello.hello
            end
      expect(out).to eq :hello
      expect(subject.locked?).to be false
    end

    it "when bo block is " do
      hello = Dystruct.new(hello: :hello)
      expect(hello).to receive(:hello).once.and_call_original
      out = subject.if_open.block_for(4) do
              hello.hello
            end
      expect(out).to eq :hello
      expect(subject.locked?).to be true
    end
  end
  describe 'if_locked' do
    around do |spec|
      subject.set(20)
      spec.run
      subject.remove
    end

    it 'executes the block when is locked' do
      out = subject.if_locked do |lock|
              subject.locked?
            end
      expect(out).to be true
      expect(subject.locked?).to eq true
    end

    it 'can access to lock and lock it after' do
      locked = nil
      subject.if_locked do |lock|
        locked = subject.locked?
        lock.remove
      end
      expect(locked).to be true
      expect(subject.locked?).to eq false
    end

    it 'when there is lock does not perform and returns nil' do
      hello = Dystruct.new(hello: :hello)
      expect(hello).to receive(:hello).once.and_call_original
      out = subject.if_locked do
              hello.hello
            end
      expect(out).to eq :hello
      expect(subject.locked?).to be true
    end
  end

  describe 'value' do
    it do
      lock = RedisLock.new('my_value')
      lock.set(60, value: 'hi there!')
      expect(lock.value).to eq 'hi there!'
      lock.delete
    end
  end
end
