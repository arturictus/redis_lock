class RedisLock
  class Semaphore < Strategy

    def call(&block)
      ttl = args[:ttl] || lock.config.default_ttl
      set_opts = args[:set_opts] || {}
      while lock.locked?
        sleep (args[:wait] || 1)
      end
      lock.set(ttl, set_opts)
      _perform(&block)
    end

    def after_perform
      lock.unlock!
    end
  end
end
