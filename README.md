# RedisLock
**use cases:**

- Do not allow anyone to perform de same operation while this is running.
- Do not perform this operation unless the previous was executed in more than 5 minutes ago.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_lock'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_lock

## Setup

This setup it's optional in any instance of `RedisLock` you can provide an optional
argument `:redis`.
But if you do not want to provided it in all the instances is a good shortcut to
set it here.

```ruby
RedisLock.setup do |config|
  # redis
  # Accepts `block` or `Hash`
  #
  # In test configuration like your `spec_helper`
  # recommend `mock_redis` gem
  # example:
  #    config.redis = -> { MockRedis.new }
  #
  # When using Sidekiq
  # example:    
  #    config.redis = -> { Sidekiq.redis{ |r| r } }
  #
  # In `Rails`
  # example:
  #     config.redis = -> do
  #       if Rails.env.test?
  #         MockRedis.new
  #       elsif Rails.env.development?
  #         { host: '127.0.0.1', port: 6379 }
  #       else
  #         Sidekiq.redis{ |r| r }
  #       end
  #     end
  config.redis = { host: '127.0.0.1'
                   port: 6379
                   db: 2 }
  # logger
  # default: Logger.new(STDOUT)
  config.logger = Rails.logger
end
```

example:

in my `spec_helper`

```ruby
RedisLock.setup do |config|
  config.redis = -> { MockRedis.new }
  config.logger = Rails.logger
end
```

## Usage

```ruby
lock = RedisLock.new('my_key')

lock.locked? #=> false
# Add 20 secs time to live (TTL)
lock.set(20) #=> true
lock.locked? #=> true
lock.remove #=> true
lock.locked? #=> false
```
__as Mutex__
```ruby
lock = RedisLock.new('my_key')
out = lock.perform do
        #no one can perform the same operation while this is running
        {}.tap do |t|
          t[:locked?] = subject.locked?
        end
      end
out[:locked?] #=> true
# once the block has finished releases the lock
lock.locked? #=> false
```

__having already a connection:_ example: Sidekiq

```ruby
Sidekiq.redis do |connection|
  lock = RedisLock.new('my_key', redis: connection)
  # do something
end
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arturictus/redis_lock.
