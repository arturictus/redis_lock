class RedisLock
  class Semaphore
    attr_reader :lock, :args

    def initialize(lock, args = {})
      @lock = lock
      @args = args
    end

    def call(&block)
      ttl = args[:ttl] || lock.config.default_ttl
      set_opts = args[:set_opts] || {}
      while lock.locked?
        sleep (args[:wait] || 3)
      end
      lock.set(ttl, set_opts)
      out = _perform(&block)
      lock.unlock!
      out
    end

    private

    def _perform(&block)
      yield lock
    rescue => e
      config.logger.error "[#{self.class}] key: `#{key}` error:"
      config.logger.error e
      raise e
    end
  end
end
