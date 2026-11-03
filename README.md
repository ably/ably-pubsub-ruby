![Ably Pub/Sub Ruby Header](https://raw.githubusercontent.com/ably/ably-pubsub-ruby/main/images/rubySDK-github.png)

[![Gem: ably-pubsub-server](https://img.shields.io/gem/v/ably-pubsub-server?label=ably-pubsub-server)](https://rubygems.org/gems/ably-pubsub-server)
[![License](https://badgen.net/github/license/ably/ably-pubsub-ruby)](https://github.com/ably/ably-pubsub-ruby/blob/main/LICENSE)

# Ably Pub/Sub Ruby SDK

The Ruby SDK for [Ably Pub/Sub](https://ably.com/docs/basics): publish and subscribe to channels,
and use message history, presence and push notification administration, from servers.

## Overview

This SDK provides the server package only, for trusted backends authenticating with an API key.
There is no device package; for end-user devices, use a device SDK such as
[JavaScript](https://github.com/ably/ably-pubsub-js), [Swift/Objective-C](https://github.com/ably/ably-pubsub-cocoa),
[Java/Android](https://github.com/ably/ably-pubsub-java), [.NET](https://github.com/ably/ably-pubsub-dotnet)
or [Flutter](https://github.com/ably/ably-pubsub-flutter).

| Package | Use it for | Entry point |
|---------|-----------|-------------|
| `ably-pubsub-server` | Servers and other trusted backend environments | `Ably::PubSub::Server.create_realtime_client`, `Ably::PubSub::Server.create_http_client` |

## Requirements

Ruby 2.7 or later (tested on 2.7 to 3.3). The SDK also needs the libcurl system library (on
Debian-based systems, install it with `apt-get install libcurl4`).

## Installation

```bash
bundle add ably-pubsub-server
```

## Quick start

Use an API key on a server. The samples read it from the `ABLY_API_KEY` environment variable; set it
to an API key from your [Ably dashboard](https://ably.com/accounts/any/apps/any/app_keys). The
following code connects, subscribes to a channel, publishes a message to it and waits for the
message to arrive.

```ruby
require 'ably/pubsub/server'

EventMachine.run do
  ably_api_key = ENV.fetch('ABLY_API_KEY')
  realtime = Ably::PubSub::Server.create_realtime_client(key: ably_api_key)
  channel = realtime.channels.get('test-channel')

  # Subscribing attaches the channel.
  channel.subscribe('test-event') do |message|
    puts "Received: #{message.data}"
    realtime.close { EventMachine.stop }
  end

  channel.attach do
    channel.publish('test-event', 'hello world')
  end
end
```

To publish over HTTP without a realtime connection, create an HTTP client instead:

```ruby
require 'ably/pubsub/server'

ably_api_key = ENV.fetch('ABLY_API_KEY')
client = Ably::PubSub::Server.create_http_client(key: ably_api_key)
client.channels.get('test-channel').publish('test-event', 'hello world')
```

> [!IMPORTANT]
> Server clients must authenticate with an API key. To use a token instead, see [Server clients and token authentication](https://ably.com/docs/auth/token#server-token-auth).

Your server also issues the tokens that devices authenticate with. Return a token request from
the endpoint your devices use as their `authUrl`:

```ruby
require 'ably/pubsub/server'

ably_api_key = ENV.fetch('ABLY_API_KEY')
client = Ably::PubSub::Server.create_http_client(key: ably_api_key)

# Authenticate the caller first. Grant only the operations this user needs.
# Without a capability, the token gets all of the API key's capabilities.
token_request = client.auth.create_token_request(
  client_id: 'me', # the authenticated user's ID
  capability: { 'test-channel' => ['publish', 'subscribe', 'history'] }
)

# Return this JSON unchanged, with the content type application/json.
puts token_request.to_json
```

See [token authentication](https://ably.com/docs/auth/token) for how devices use it.

## Migrating from 1.x

Version 2.0 renames the gem and creates clients with factory methods.

| | 1.x | 2.0 |
|---|---|---|
| Package | `ably` or `ably-rest` | `ably-pubsub-server` |
| Require | `require 'ably'` or `require 'ably-rest'` | `require 'ably/pubsub/server'` |
| Realtime client | `Ably::Realtime::Client.new(key: key)` | `Ably::PubSub::Server.create_realtime_client(key: key)` |
| HTTP client | `Ably::Rest::Client.new(key: key)` | `Ably::PubSub::Server.create_http_client(key: key)` |

See [UPDATING.md](https://github.com/ably/ably-pubsub-ruby/blob/main/UPDATING.md#version-1x-ably-gem-to-200-ably-pubsub-server-gem) for all other changes.

## Common configuration

Both factories accept an API key or token string, or an options `Hash`.

### Endpoint

`endpoint` selects the Ably host for HTTP requests and the realtime connection. It replaces the
1.x `environment`, `rest_host` and `realtime_host` options. 2.0 ignores those options, so a client
that still sets them connects to production.

```ruby
ably_api_key = ENV.fetch('ABLY_API_KEY')
realtime = Ably::PubSub::Server.create_realtime_client(key: ably_api_key, endpoint: 'nonprod:sandbox')
```

- Never put a port in `endpoint`: `localhost:8080` is not a hostname and does not resolve.
- Set the port with `tls_port`, or with `port` when TLS is off.
- With TLS off (`tls: false`), use token authentication.

See [UPDATING.md](https://github.com/ably/ably-pubsub-ruby/blob/main/UPDATING.md#connection-options-endpoint) for how the old options map to
`endpoint`.

### Logging

Set `log_level` to `:fatal`, `:error`, `:warn` (the default), `:info`, `:debug` or `:none`. Logs
go to standard output through Ruby's `Logger`. To send them elsewhere, pass a `Logger`-compatible
object as `logger`:

```ruby
require 'logger'
require 'ably/pubsub/server'

ably_api_key = ENV.fetch('ABLY_API_KEY')
client = Ably::PubSub::Server.create_http_client(
  key: ably_api_key,
  log_level: :debug,
  logger: Logger.new($stderr)
)
```

## Platform notes

### EventMachine

- The realtime client runs on [EventMachine](https://github.com/eventmachine/eventmachine). Create
  and use it inside `EventMachine.run`.
- The HTTP client is synchronous. It does not need the EventMachine reactor.
- The gem depends on EventMachine even if you use only the HTTP client.

## Known limitations

- [LiveObjects](https://ably.com/docs/liveobjects) is not supported.
- [Token revocation](https://ably.com/docs/auth/revocation) is not supported.
- [Delta compression](https://ably.com/docs/channels/options/deltas) is not supported.
- A Ruby client cannot be a [push notification](https://ably.com/docs/push) target. The push
  admin API is supported.

## Further reading

- [Getting started with Pub/Sub using Ruby](https://ably.com/docs/getting-started/ruby)
- [Ably Pub/Sub documentation](https://ably.com/docs/basics) and [examples](https://ably.com/examples?product=pubsub)
- [Token authentication](https://ably.com/docs/auth/token)
- [UPDATING.md](https://github.com/ably/ably-pubsub-ruby/blob/main/UPDATING.md): migrating from 1.x
- [CHANGELOG.md](https://github.com/ably/ably-pubsub-ruby/blob/main/CHANGELOG.md): release notes; all Ably releases are listed on [changelog.ably.com](https://changelog.ably.com)

## Contributing

Read [CONTRIBUTING.md](https://github.com/ably/ably-pubsub-ruby/blob/main/CONTRIBUTING.md) before contributing; it also describes the release
process.

## Support, feedback and troubleshooting

For help, visit Ably's [support page](https://ably.com/support). Report bugs and compatibility
problems on [GitHub Issues](https://github.com/ably/ably-pubsub-ruby/issues).

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](https://github.com/ably/ably-pubsub-ruby/blob/main/LICENSE).
