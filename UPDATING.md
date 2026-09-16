# Upgrade / Migration Guide

## Version 1.x (`ably` gem) to 2.0.0 (`ably-pubsub-server` gem)

### Gemfile

```ruby
# 1.x
gem 'ably'

# 2.0
gem 'ably-pubsub-server'
```

### Require

```ruby
# 1.x
require 'ably'

# 2.0
require 'ably/pubsub/server'
```

### HTTP client

```ruby
# 1.x
client = Ably::Rest::Client.new(key: ENV['ABLY_API_KEY'])
client = Ably::Rest::Client.new('key.id:secret')
client = Ably::Rest::Client.new(token: 'token')
client = Ably::Rest.new(key: ENV['ABLY_API_KEY'])

# 2.0
client = Ably::PubSub::Server.create_http_client(key: ENV['ABLY_API_KEY'])
client = Ably::PubSub::Server.create_http_client('key.id:secret')
client = Ably::PubSub::Server.create_http_client(token: 'token')
```

### Realtime client

```ruby
# 1.x
client = Ably::Realtime::Client.new(key: ENV['ABLY_API_KEY'])
client = Ably::Realtime::Client.new('key.id:secret')
client = Ably::Realtime.new(key: ENV['ABLY_API_KEY'])

# 2.0
client = Ably::PubSub::Server.create_realtime_client(key: ENV['ABLY_API_KEY'])
client = Ably::PubSub::Server.create_realtime_client('key.id:secret')
```

Both factories accept an options `Hash`, an API key `String`, or a token `String`.

`Ably::PubSub::Http::Client.new` and `Ably::PubSub::Realtime::Client.new` raise
`Ably::Exceptions::DirectConstructionNotSupported`.

### Namespaces

| 1.x | 2.0 |
| --- | --- |
| `Ably::Rest::*` | `Ably::PubSub::Http::*` |
| `Ably::Realtime::*` | `Ably::PubSub::Realtime::*` |

```ruby
# 1.x
client.is_a?(Ably::Rest::Client)
Ably::Rest::Client::MAX_MESSAGE_SIZE
Ably::Realtime::Channel::STATE.Attached
Ably::Realtime::Connection::STATE.Connected

# 2.0
client.is_a?(Ably::PubSub::Http::Client)
Ably::PubSub::Http::Client::MAX_MESSAGE_SIZE
Ably::PubSub::Realtime::Channel::STATE.Attached
Ably::PubSub::Realtime::Connection::STATE.Connected
```

`Ably::Rest` and `Ably::Realtime` raise `NameError` in 2.0.

### Unchanged

Everything after construction:

```ruby
client = Ably::PubSub::Server.create_http_client(key: ENV['ABLY_API_KEY'])

channel = client.channels.get('example')
channel.publish 'event', 'payload'
channel.history
channel.presence.get

client.auth.request_token
client.stats
client.time
```

```ruby
client = Ably::PubSub::Server.create_realtime_client(key: ENV['ABLY_API_KEY'])

client.connection.on(:connected) { }

channel = client.channels.get('example')
channel.attach
channel.subscribe { |message| }
channel.publish 'event', 'payload'
channel.presence.enter
```

## Version 1.1.8 to 1.2.0

### Notable Changes
This release is all about channel options. Here is the full [changelog](https://github.com/ably/ably-ruby/blob/main/CHANGELOG.md)

* Channel options were extracted into a seperate model [ChannelOptions](https://github.com/ably/ably-ruby/blob/main/lib/ably/models/channel_options.rb). However it's still backward campatible with `Hash` and you don't need to do make any adjustments to your code

* The `ChannelOptions` class now supports `:params`, `:modes` and `:cipher` as options. Previously only `:cipher` was available

* The client `:idempotent_rest_publishing` option is `true` by default. Previously `:idempotent_rest_publishing` was `false` by default.

### Breaking Changes

* Changing channel options with `Channels#get` is now deprecated in favor of explicit options change

  1. If channel state is attached or attaching an exception will be raised
  2. Otherwise the library will emit a warning

For example, the following code
```
  client.channels.get(channel_name, new_channel_options)
```

Should be changed to:
```
  channel = client.channels.get(channel_name)
  channel.options = new_channel_options
```
