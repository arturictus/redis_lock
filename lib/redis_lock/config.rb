class RedisLock
  class Config
    def redis=(hash = {})
      @redis = hash
    end

    def redis
      fail "[RedisLock::Config] redis connection setup is not set" unless @redis
      @redis
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ? @logger : Logger.new(STDOUT)
    end
  end
end
