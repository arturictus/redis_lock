class RedisLock
  class Strategy
    attr_reader :lock, :args

    def initialize(lock, args = {})
      @lock = lock
      @args = args
    end

    def call(&block)
      raise NotImplementedError
    end

    def after_perform
    end

    private

    def _perform(&block)
      yield lock
    rescue => e
      lock.config.logger.error "[#{self.class}] key: `#{key}` error:"
      lock.config.logger.error e
      raise e
    ensure
      after_perform
    end
  end
end
