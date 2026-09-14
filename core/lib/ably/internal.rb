module Ably
  # Construction entry points for Ably's own per-side packages: +ably-pubsub-server+, and
  # any future device-side package.
  #
  # Applications must not use this module. It carries no compatibility guarantee and may
  # change in any release, including a patch. Use the factory functions of the package you
  # installed — see {Ably::PubSub::Server} in the +ably-pubsub-server+ gem.
  #
  # The client classes refuse direct construction ({Ably::Rest::Client.new} and
  # {Ably::Realtime::Client.new} raise {Ably::Exceptions::DirectConstructionNotSupported}),
  # because the package a client is created from is what declares the client's side to the
  # platform and a directly constructed client declares none. These entry points are how a
  # per-side package constructs the client it has stamped its side onto.
  module Internal
    class << self
      # Constructs an {Ably::Rest::Client}, bypassing the direct-construction refusal.
      #
      # @param options [Hash, String] as accepted by {Ably::Rest::Client#initialize}
      # @return [Ably::Rest::Client]
      # @api private
      def create_rest_client(options)
        construct(Ably::Rest::Client, options)
      end

      # Constructs an {Ably::Realtime::Client}, bypassing the direct-construction refusal.
      #
      # @param options [Hash, String] as accepted by {Ably::Realtime::Client#initialize}
      # @return [Ably::Realtime::Client]
      # @api private
      def create_realtime_client(options)
        construct(Ably::Realtime::Client, options)
      end

      # Builds the error raised when a client is constructed directly. Shared so the
      # refusals on the client classes and on the Ably::Rest / Ably::Realtime convenience
      # aliases all speak with one voice.
      #
      # @param subject [String] the unsupported call, e.g. +"Ably::Rest::Client.new"+
      # @param factory [String] the supported call to use instead
      # @return [Ably::Exceptions::DirectConstructionNotSupported]
      # @api private
      def direct_construction_error(subject, factory)
        Ably::Exceptions::DirectConstructionNotSupported.new <<~MSG
          #{subject} is not supported: Ably clients cannot be constructed directly.

          Use the factory function of the Ably package you installed, for example:
            #{factory}   # ably-pubsub-server

          The package a client is created from is what declares the client's side to the
          platform. A directly constructed client declares none, so the platform cannot
          classify it for MAU billing.
        MSG
      end

      private

      # +allocate+ skips the class's overridden +new+, so +initialize+ has to be invoked
      # explicitly. Every client instance in the library is built through here.
      def construct(klass, options)
        klass.allocate.tap { |client| client.send(:initialize, options) }
      end
    end
  end
end
