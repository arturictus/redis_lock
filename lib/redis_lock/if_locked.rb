class RedisLock
  class IfLocked < Strategy
    def call(&block)
      return :open if lock.open?
      _perform(&block)
    end
  end
end
