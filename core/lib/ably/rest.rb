require 'ably/rest/channel'
require 'ably/rest/channels'
require 'ably/rest/client'
require 'ably/rest/push'
require 'ably/rest/presence'

require 'ably/models/message_encoders/base'

Dir.glob(File.expand_path("models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

module Ably
  # Rest is the namespace of the stateless HTTP client and the models it returns.
  #
  # @example
  #   client = Ably::PubSub::Server.create_http_client("xxxxx")
  #   channel = client.channel("test")
  #   channel.publish "greeting", "data"
  #
  module Rest
    # Refuses construction. This was a convenience alias for the {Ably::Rest::Client}
    # constructor, which no longer accepts direct construction: the package a client is
    # created from is what declares the client's side to the platform, and a client
    # constructed here declares none.
    #
    # Use {Ably::PubSub::Server.create_http_client} from the +ably-pubsub-server+ gem.
    #
    # @raise [Ably::Exceptions::DirectConstructionNotSupported] always
    def self.new(*args, **kwargs, &block)
      raise Ably::Internal.direct_construction_error(
        'Ably::Rest.new', 'Ably::PubSub::Server.create_http_client(options)'
      )
    end
  end
end
