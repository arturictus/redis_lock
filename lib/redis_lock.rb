require 'redis'
require "redis_lock/version"
require "redis_lock/configuration"

class RedisLock
  attr_reader :key

  def self.config
    @config ||= Configuration.new
  end

  def self.setup
    yield config
  end

  def self.semaphore(key, args = {}, &block)
    setup_instance(key, args).semaphore(args, &block)
  end

  def self.if_open(key, args = {}, &block)
    setup_instance(key, args).if_open(args, &block)
  end

  def self.if_locked(key, args = {}, &block)
    setup_instance(key, args).if_locked(args, &block)
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

  def semaphore(args = {}, &block)
    ttl = args[:ttl] || config.default_ttl
    set_opts = args[:set_opts] || {}
    while locked?
      sleep (args[:wait] || 3)
    end
    set(ttl, set_opts)
    out = _perform(&block)
    unlock!
    out
  end

  def if_open(args = {}, &block)
    return if locked?
    _perform(&block)
  end
  alias_method :perform, :if_open

  def if_locked(args = {}, &block)
    return if open?
    _perform(&block)
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

  private

  def self.setup_instance(key, args)
    inst_opts = { redis: args.delete(:redis) }.reject{ |_, v| v.nil? }
    new(key, inst_opts)
  end

  def _perform(&block)
    yield self
  rescue => e
    config.logger.error "[#{self.class}] key: `#{key}` error:"
    config.logger.error e
    raise e
  end
end
