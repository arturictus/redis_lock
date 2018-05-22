class RedisLock
  class IfLocked < Semaphore
    def call(&block)
      return :open if lock.open?
      _perform(&block)
    end
  end
end
