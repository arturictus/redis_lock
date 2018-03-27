require 'logger'
class RedisLock
  class Configuration
    class RedisNotSet < StandardError; end
    def redis=(hash = {})
      @redis = hash
    end

    def redis
      fail RedisNotSet, "[#{self.class}] redis connection setup is not set" unless @redis
      if @redis.respond_to?(:call)
        return @redis.call
      else
        self.redis_instance = @redis
        @redis_instance
      end
    end


    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger || Logger.new(STDOUT)
    end

    def default_ttl=(val)
      @default_ttl = val
    end

    def default_ttl
      @default_ttl || 60
    end

    private

    def redis_instance=(args)
      @redis_instance ||= Redis.new(args)
    end
  end
end
