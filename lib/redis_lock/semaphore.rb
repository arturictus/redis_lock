class RedisLock
  class Semaphore < Strategy
    attr_reader :lock_caller
    def call(&block)
      self.lock_caller = block
      ttl = args[:ttl] || lock.config.default_ttl
      set_opts = args[:set_opts] || {}
      while lock.locked?
        sleep (args[:wait] || 1)
      end
      lock.set(ttl, set_opts)
      _perform(&block)
    end

    def safe_lock?
      return true if lock.value == lock_caller
      if caller.any? { |f|  f =~ lock.value }
        false
      else
        true
      end
    end

    def lock_caller=(block)
      @lock_caller = block.to_s.split("@").last
    end

    def after_perform
      lock.unlock!
    end
  end
end
