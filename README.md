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

```ruby
RedisLock.setup do |config|
  config.redis = { host: '127.0.0.1'
                   port: 6379
                   db: 2 }
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

```ruby
lock = RedisLock.new('my_key')
out = subject.perform do
        #no one can perform the same operation while this is running
        {}.tap do |t|
          t[:locked?] = subject.locked?
        end
      end
out[:locked?] #=> true
# once the block has finished releases the lock
lock.locked? #=> false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arturictus/redis_lock.
