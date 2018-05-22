class RedisLock
  class MultiLock
    extend Forwardable
    attr_reader :keys, :args, :locks, :opts
    def_delegators :locks, :any?, :all?, :each, :map

    def initialize(*args)
      @args = args.dup
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
      map { |l| l.set(ttl, opts) }.all?{ |e| e === true }
    end

    def config
      RedisLock.config
    end

    def delete
      map(&:delete).all?{ |e| e === true }
    end
    alias_method :unlock!, :delete
    alias_method :open!, :delete
    alias_method :remove, :delete

    def open?
      all?(&:open?)
    end
    alias_method :unlocked?, :open?

    def locked?
      any?(&:locked?)
    end
    alias_method :exists?, :locked?
    alias_method :in_use?, :locked?
  end
end
