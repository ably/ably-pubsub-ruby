require 'eventmachine'
require 'websocket/driver'
require 'em-http-request'

require 'ably/modules/event_emitter'

require 'ably/pubsub/realtime/auth'
require 'ably/pubsub/realtime/channel'
require 'ably/pubsub/realtime/channels'
require 'ably/pubsub/realtime/client'
require 'ably/pubsub/realtime/connection'
require 'ably/pubsub/realtime/push'
require 'ably/pubsub/realtime/presence'

require 'ably/models/message_encoders/base'

Dir.glob(File.expand_path("../models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

Dir.glob(File.expand_path("realtime/models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

require 'ably/models/message_encoders/base'

require 'ably/pubsub/realtime/client/incoming_message_dispatcher'
require 'ably/pubsub/realtime/client/outgoing_message_dispatcher'

module Ably
  module PubSub
    # Realtime is the namespace of the stateful realtime client and the models it returns.
    #
    # @example
    #   client = Ably::PubSub::Server.create_realtime_client("xxxxx")
    #   channel = client.channel("test")
    #   channel.subscribe do |message|
    #     message[:name] #=> "greeting"
    #   end
    #   channel.publish "greeting", "data"
    #
    module Realtime
      # Refuses construction. This was a convenience alias for the {Ably::PubSub::Realtime::Client}
      # constructor, which no longer accepts direct construction: the package a client is
      # created from is what declares the client's side to the platform, and a client
      # constructed here declares none.
      #
      # Use {Ably::PubSub::Server.create_realtime_client} from the +ably-pubsub-server+ gem.
      #
      # @raise [Ably::Exceptions::DirectConstructionNotSupported] always
      def self.new(*args, **kwargs, &block)
        raise Ably::Internal.direct_construction_error(
          'Ably::PubSub::Realtime.new', 'Ably::PubSub::Server.create_realtime_client(options)'
        )
      end
    end
  end
end
