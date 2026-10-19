require 'ably/pubsub/http/channel'
require 'ably/pubsub/http/channels'
require 'ably/pubsub/http/client'
require 'ably/pubsub/http/push'
require 'ably/pubsub/http/presence'

require 'ably/models/message_encoders/base'

Dir.glob(File.expand_path("../models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

module Ably
  module PubSub
    # Http is the namespace of the stateless HTTP client and the models it returns.
    #
    # @example
    #   client = Ably::PubSub::Server.create_http_client("xxxxx")
    #   channel = client.channel("test")
    #   channel.publish "greeting", "data"
    #
    module Http
      # Refuses construction. This was a convenience alias for the {Ably::PubSub::Http::Client}
      # constructor, which no longer accepts direct construction: the package a client is
      # created from is what declares the client's side to the platform, and a client
      # constructed here declares none.
      #
      # Use {Ably::PubSub::Server.create_http_client} from the +ably-pubsub-server+ gem.
      #
      # @raise [Ably::Exceptions::DirectConstructionNotSupported] always
      def self.new(*args, **kwargs, &block)
        raise Ably::Internal.direct_construction_error(
          'Ably::PubSub::Http.new', 'Ably::PubSub::Server.create_http_client(options)'
        )
      end
    end
  end
end
