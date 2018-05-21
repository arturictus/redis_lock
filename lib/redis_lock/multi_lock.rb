class RedisLock
  class MultiLock
    extend Forwardable
    attr_reader :keys, :args, :locks
    def_delegators [:any?, :all?, :each] => :locks
    def initialize(*args)
      @args = args
      @opts = extract_options!
      @keys = args
      @locks = @keys.map do |k|
                 RedisLock.new(k, @opts)
               end
    end

    def extract_options!
      args.last.is_a?(::Hash) ? args.pop : {}
    end

    def set(ttl, opts = {})
      each { |l| l.set(ttl, opts) }
    end

    def config
      RedisLock.config
    end

    def unlock!
      each(&:unlock!)
    end

    def locked?
      any?(&:locked?)
    end
  end
end
