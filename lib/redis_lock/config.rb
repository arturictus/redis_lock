class RedisLock
  class Config
    def redis=(hash = {})
      @redis = hash
    end

    def redis
      raise "[RedisLock::Config] redis connection is not set" unless @redis
      @redis
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger
    end
  end
end
