require 'redis'
require "redis_lock/version"

class RedisLock
  attr_reader :key

  def self.config
    @config ||= Configuration.new
  end

  def self.setup
    yield config
  end

  def self.semaphore(*args, &block)
    opts = extract_options!(args)
    Semaphore.new(MultiLock.new(*args, opts), opts).call(&block)
  end

  def self.if_open(*args, &block)
    opts = extract_options!(args)
    inst = IfOpen.new(MultiLock.new(*args, opts), opts)
    block ? inst.call(&block) : inst
  end

  def self.if_locked(*args, &block)
    opts = extract_options!(args)
    IfLocked.new(MultiLock.new(*args, opts), opts).call(&block)
  end

  def config; self.class.config; end

  def initialize(key, opts = {})
    @key = "REDISLOCK::#{key}"
    @redis = opts[:redis]
  end

  def redis
    @redis ||= config.redis
  end

  # Redis SET options:
  # - EX seconds -- Set the specified expire time, in seconds.
  # - PX milliseconds -- Set the specified expire time, in milliseconds.
  # - NX -- Only set the key if it does not already exist.
  # - XX -- Only set the key if it already exist.
  def set(expiration_time = 60, opts = {})
    value = opts.delete(:value) || Time.now.strftime('%FT%T')
    args = if opts[:px]
             { px: expiration_time }
           else
             { ex: expiration_time }
           end
    redis.set(key, value, args.merge(opts)) == "OK" ? true : false
  end

  def semaphore(opts = {}, &block)
    Semaphore.new(self, opts).call(&block)
  end

  def if_open(opts = {}, &block)
    IfOpen.new(self, opts).call(&block)
  end
  alias_method :perform, :if_open

  def if_locked(opts = {}, &block)
    IfLocked.new(self, opts).call(&block)
  end

  def locked?
    ttl == -2 ? false : true
  end
  alias_method :exists?, :locked?
  alias_method :in_use?, :locked?

  def ttl
    redis.ttl(key)
  end

  def open?
    !locked?
  end
  alias_method :unlocked?, :open?

  def delete
    redis.del(key) == 1 ? true : false
  end
  alias_method :unlock!, :delete
  alias_method :open!, :delete
  alias_method :remove, :delete

  def value
    redis.get(key)
  end

  def self.extract_options!(args)
    args.last.is_a?(::Hash) ? args.pop : {}
  end
end

require "redis_lock/configuration"
require "redis_lock/strategy"
require "redis_lock/semaphore"
require "redis_lock/if_open"
require "redis_lock/if_locked"
require "redis_lock/multi_lock"
