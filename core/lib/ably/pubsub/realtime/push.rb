require 'ably/pubsub/realtime/push/admin'

module Ably
  module PubSub
    module Realtime
      # Class providing push notification functionality
      class Push
        # @private
        attr_reader :client

        def initialize(client)
          @client = client
        end

        # A {Ably::PubSub::Realtime::Push::Admin} object.
        #
        # @spec RSH1
        #
        # @return [Ably::PubSub::Realtime::Push::Admin]
        #
        def admin
          @admin ||= Admin.new(self)
        end
      end
    end
  end
end
