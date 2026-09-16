module Ably
  # The namespace of Ably's Pub/Sub packages. The implementation lives here
  # (+Ably::PubSub::Http+, +Ably::PubSub::Realtime+ and their models), and each per-side
  # package adds its own factory module alongside — +Ably::PubSub::Server+ from the
  # +ably-pubsub-server+ gem.
  #
  # This file only opens the namespace. Files that declare into it with the compact form
  # (+module Ably::PubSub::Http+) need it to exist already, so it is required first.
  module PubSub
  end
end
