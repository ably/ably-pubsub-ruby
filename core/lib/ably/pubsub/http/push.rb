require 'ably/pubsub/http/push/admin'

module Ably
  module PubSub
    module Http
      # Class providing push notification functionality
      class Push
        include Ably::Modules::Conversions

        # @private
        attr_reader :client

        def initialize(client)
          @client = client
        end

        # Admin features for push notifications like managing devices and channel subscriptions
        #
        # @return [Ably::PubSub::Http::Push::Admin]
        #
        def admin
          @admin ||= Admin.new(self)
        end
      end
    end
  end
end
