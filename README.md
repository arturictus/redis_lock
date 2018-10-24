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
But if you do not want to provide it in all the instances is a good shortcut to
set it here.

```ruby
RedisLock.setup do |config|
  # redis
  # Accepts `block` (or something responding to `#call`) or `Hash`
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

  # Default ttl for all your locks
  # default: 60
  #
  # config.default_ttl = 120
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


__semaphore:__
No one can perform the same operation while this is running the rest of the processes
are waiting while the lock is in use, When lock is released another one takes the lock.

args:
  - key [string]
  - opts: `{}`
    * :redis
    * :ttl, time to live
    * :set_opts, check `set` documentation
    * :wait, time waiting for the next check if the lock is in use

```ruby
out = RedisLock.semaphore('my_key') do |l|
        sleep 3 # Do something
        :hello
      end
out #=> :hello
RedisLock.new('my_key').locked? #=> false
```

_multiple locks:_

Very useful when you are changing multiple objects and want to protect them
in a distributed system

```ruby
lock_1 = RedisLock.new('my_key')
lock_2 = RedisLock.new('another_key')

out = RedisLock.semaphore('my_key', 'another_key') do |multi_lock|
        multi_lock.locked? #=> true
        lock_1.locked? #=> true
        lock_2.locked? #=> true
        sleep 3 # Do something
        :hello
      end
out #=> :hello
lock_1.locked? #=> false
lock_2.locked? #=> false
```

__if_open:__

**Use case:**
Send email to user. The User should receive only 1 email per day

```ruby
ttl = (24 * 3600) # one day
RedisLock.if_open("User:1-sales-products", ttl: ttl) do |l|
  # Send Email
  l.set(ttl)
end
```

## Methods:

### set

Will store the key to redis with a ttl (time to live).
args:
  - __ttl__ | default: 60
  - __opts__ | default: {}
    * __value__ (String) - default: time now
    * __px__  - miliseconds instead of seconds | default: false
    * __nk__  - Only set the key if it does not already exist. | default: false
    * __xx__  - Only set the key if it already exist. | default: false
```ruby
lock = RedisLock.new('my_key')

lock.set(60)
lock.ttl #=> 60
lock.open? # => false
```

__with options:__

```ruby
lock = RedisLock.new('my_key')

lock.set(60, nx: true) # only if the key does not exists
# => true (key has been stored)
lock.ttl #=> 60
lock.open? # => false
```

Redis documentation: https://redis.io/commands/set
```
Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type. Any previous time to live associated with the key is discarded on successful SET operation.

EX seconds -- Set the specified expire time, in seconds.
PX milliseconds -- Set the specified expire time, in milliseconds.
NX -- Only set the key if it does not already exist.
XX -- Only set the key if it already exist.
```

### locked?

Returns `true` if lock is set

```ruby
lock = RedisLock.new('my_key')
lock.set(60) # => true (key has been stored)
lock.locked? # => true
lock.remove
lock.locked? # => false
```
_alias method:_ `exists?`

### open?

Returns `true` if NO lock is set

```ruby
lock = RedisLock.new('my_key')
lock.open? # => true
lock.set(60) # => true (key has been stored)
lock.open? # => false
```
_alias method:_ `unlocked?`

### delete

Removes the key from the Redis store

```ruby
lock = RedisLock.new('my_key')
lock.set(60) # => true (key has been stored)
lock.locked? # => true
lock.delete
lock.locked? # => false
```
_alias methods:_ `unlock!`,`open!`

### value

Returns the value stored in redis

```ruby
lock = RedisLock.new('my_key')
lock.set(60, value: 'hi there!')
lock.value # => 'hi there!'
```
### ttl

Returns the pending ttl (time to live)

```ruby
lock = RedisLock.new('my_key')
lock.set(60)
lock.ttl # => 60
sleep 10
lock.ttl # => 50
```

__having already a connection:__ _example: Sidekiq_

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
