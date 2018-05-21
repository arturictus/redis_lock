class RedisLock
  class IfLocked < Semaphore
    def call(&block)
      return if lock.locked?
      _perform(&block)
    end
  end
end
