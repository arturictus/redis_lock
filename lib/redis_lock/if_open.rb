class RedisLock
  class IfOpen < Strategy
    def call(&block)
      return :locked if lock.locked?
      _perform(&block)
    end
  end
end
