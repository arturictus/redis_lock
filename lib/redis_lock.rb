require 'redis'
require "redis_lock/version"
require "redis_lock/config"

class RedisLock
  attr_reader :key

  def self.config
    @config ||= Config.new
  end

  def self.setup
    yield config
  end

  def config; self.class.config; end

  def initialize(key, opts = {})
    @key = key
    @redis = opts[:redis]
  end

  def redis
    @redis ||= Redis.new(config.redis)
  end

  def set(expiration_time = 600)
    redis.set(
      key,
      Time.now.strftime('%FT%T'),
      ex: expiration_time, # expires in X seconds
      nx: true # only if it does not exists
    )
  end

  def perform(args = {}, &block)
    return if locked?
    expiration = args[:expiration] || args[:ex] || 600
    set(expiration)
    # If error occurs, we remove the lock
    out = _perform(&block)
    remove
    out
  end



  def locked?
    redis.ttl(key) == -2 ? false : true
  end
  alias_method :exists?, :locked?

  def remove
    redis.del(key) == 1 ? true : false
  end

  private

  def _perform(&block)
    yield self
  rescue => e
    config.logger.error "[RedisLock] key: `#{key}` error:"
    config.logger.error e
    false
  end
end
