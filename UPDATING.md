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

### Connection options: `endpoint`

The `:endpoint` option is now the only way to choose where a client connects. The
`:environment`, `:rest_host`, `:realtime_host` (and its alias `:ws_host`) and
`:fallback_hosts_use_default` options have been removed and are ignored, so a client that
still passes them connects to production (`main.realtime.ably.net`).

| 1.x | 2.0 |
| --- | --- |
| no host options | no change; traffic moves to `main.realtime.ably.net` |
| `environment: 'sandbox'` | `endpoint: 'nonprod:sandbox'` |
| `environment: 'acme'` (dedicated cluster) | `endpoint: 'acme'` |
| `rest_host:` / `realtime_host: 'localhost'` | `endpoint: 'localhost'` |
| `rest_host` and `realtime_host` set to the same custom host | `endpoint: '<that host>'` |
| `rest_host` and `realtime_host` set to different hosts | not supported; use one host that serves both, or contact Ably |
| `fallback_hosts_use_default: true` | delete it |
| custom `fallback_hosts` | unchanged |

```ruby
# 1.x
client = Ably::Rest::Client.new(key: ENV['ABLY_API_KEY'], environment: 'sandbox')

# 2.0
client = Ably::PubSub::Server.create_http_client(key: ENV['ABLY_API_KEY'], endpoint: 'nonprod:sandbox')
```

REST requests and the realtime connection now use the same primary domain:

| `endpoint` | Primary domain | Default fallback hosts |
| --- | --- | --- |
| unset | `main.realtime.ably.net` | `main.[a-e].fallback.ably-realtime.com` |
| `'acme'` | `acme.realtime.ably.net` | `acme.[a-e].fallback.ably-realtime.com` |
| `'nonprod:sandbox'` | `sandbox.realtime.ably-nonprod.net` | `sandbox.[a-e].fallback.ably-realtime-nonprod.com` |
| a hostname, such as `'localhost'`, `'127.0.0.1'` or `'ably.example.com'` | the hostname | none |

A custom `port` or `tls_port` no longer disables the default fallback hosts; pass
`fallback_hosts: []` to disable them.

Firewall allowlists and proxies must allow `*.realtime.ably.net` and
`*.fallback.ably-realtime.com` in place of `rest.ably.io`, `realtime.ably.io` and
`*.ably-realtime.com`.

Related client attributes:

| 1.x | 2.0 |
| --- | --- |
| `client.endpoint` (a `URI`) | `client.uri`; `client.endpoint` now returns the `:endpoint` option |
| `client.environment` | `client.endpoint` |
| `client.custom_host`, `realtime_client.custom_realtime_host` | `client.primary_domain` |
| `Ably::PubSub::Http::Client::DOMAIN`, `Ably::PubSub::Realtime::Client::DOMAIN` | `client.primary_domain` |
| `Ably::CUSTOM_ENVIRONMENT_FALLBACKS_SUFFIXES` | removed |

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
