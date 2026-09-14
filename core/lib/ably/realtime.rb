require 'eventmachine'
require 'websocket/driver'
require 'em-http-request'

require 'ably/modules/event_emitter'

require 'ably/realtime/auth'
require 'ably/realtime/channel'
require 'ably/realtime/channels'
require 'ably/realtime/client'
require 'ably/realtime/connection'
require 'ably/realtime/push'
require 'ably/realtime/presence'

require 'ably/models/message_encoders/base'

Dir.glob(File.expand_path("models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

Dir.glob(File.expand_path("realtime/models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

require 'ably/models/message_encoders/base'

require 'ably/realtime/client/incoming_message_dispatcher'
require 'ably/realtime/client/outgoing_message_dispatcher'

module Ably
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
    # Refuses construction. This was a convenience alias for the {Ably::Realtime::Client}
    # constructor, which no longer accepts direct construction: the package a client is
    # created from is what declares the client's side to the platform, and a client
    # constructed here declares none.
    #
    # Use {Ably::PubSub::Server.create_realtime_client} from the +ably-pubsub-server+ gem.
    #
    # @raise [Ably::Exceptions::DirectConstructionNotSupported] always
    def self.new(*args, **kwargs, &block)
      raise Ably::Internal.direct_construction_error(
        'Ably::Realtime.new', 'Ably::PubSub::Server.create_realtime_client(options)'
      )
    end
  end
end
