class RedisLock
  class IfOpen < Semaphore
    def call(&block)
      return if lock.locked?
      _perform(&block)
    end
  end
end
