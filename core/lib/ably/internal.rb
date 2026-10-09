module Ably
  # Construction entry points for Ably's own per-side packages: +ably-pubsub-server+, and
  # any future device-side package, plus endpoint resolution shared by the clients.
  #
  # Applications must not use this module. It carries no compatibility guarantee and may
  # change in any release, including a patch. Use the factory functions of the package you
  # installed — see {Ably::PubSub::Server} in the +ably-pubsub-server+ gem.
  #
  # The client classes refuse direct construction ({Ably::PubSub::Http::Client.new} and
  # {Ably::PubSub::Realtime::Client.new} raise {Ably::Exceptions::DirectConstructionNotSupported}),
  # because the package a client is created from is what declares the client's side to the
  # platform and a directly constructed client declares none. These entry points are how a
  # per-side package constructs the client it has stamped its side onto.
  module Internal
    # Prefix of an +:endpoint+ value that selects a non-production routing policy, such as +nonprod:sandbox+
    NONPROD_ENDPOINT_PREFIX = 'nonprod:'.freeze
    NONPROD_ROOT_DOMAIN = 'ably-nonprod.net'.freeze
    NONPROD_FALLBACK_DOMAIN = 'ably-realtime-nonprod.com'.freeze
    private_constant :NONPROD_ENDPOINT_PREFIX, :NONPROD_ROOT_DOMAIN, :NONPROD_FALLBACK_DOMAIN

    class << self
      # Constructs an {Ably::PubSub::Http::Client}, bypassing the direct-construction refusal.
      #
      # @param options [Hash, String] as accepted by {Ably::PubSub::Http::Client#initialize}
      # @return [Ably::PubSub::Http::Client]
      # @api private
      def create_http_client(options)
        construct(Ably::PubSub::Http::Client, options)
      end

      # Constructs an {Ably::PubSub::Realtime::Client}, bypassing the direct-construction refusal.
      #
      # @param options [Hash, String] as accepted by {Ably::PubSub::Realtime::Client#initialize}
      # @return [Ably::PubSub::Realtime::Client]
      # @api private
      def create_realtime_client(options)
        construct(Ably::PubSub::Realtime::Client, options)
      end

      # Builds the error raised when a client is constructed directly. Shared so the
      # refusals on the client classes and on the Ably::PubSub::Http /
      # Ably::PubSub::Realtime convenience aliases all speak with one voice.
      #
      # @param subject [String] the unsupported call, e.g. +"Ably::PubSub::Http::Client.new"+
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

      # Returns the primary domain for the given +:endpoint+ client option value
      #
      # @spec REC1b2, REC1b3, REC1b4
      # @param endpoint [String] a routing policy name such as +main+, a +nonprod:[id]+ routing policy, or a hostname
      # @return [String]
      # @api private
      def primary_domain(endpoint)
        return endpoint if hostname_endpoint?(endpoint)

        if nonprod_endpoint?(endpoint)
          "#{nonprod_endpoint_id(endpoint)}.realtime.#{NONPROD_ROOT_DOMAIN}"
        else
          "#{endpoint}.realtime.#{Ably::PROD_ROOT_DOMAIN}"
        end
      end

      # Returns the default fallback domains for the given +:endpoint+ client option value
      #
      # @spec REC2c1, REC2c2, REC2c3, REC2c4
      # @param endpoint [String] a routing policy name such as +main+, a +nonprod:[id]+ routing policy, or a hostname
      # @return [Array<String>] empty when +endpoint+ is a hostname
      # @api private
      def fallback_domains(endpoint)
        return [] if hostname_endpoint?(endpoint)

        if nonprod_endpoint?(endpoint)
          Ably::FALLBACK_IDS.map { |id| "#{nonprod_endpoint_id(endpoint)}.#{id}.fallback.#{NONPROD_FALLBACK_DOMAIN}" }
        else
          Ably::FALLBACK_IDS.map { |id| "#{endpoint}.#{id}.fallback.#{Ably::PROD_FALLBACK_DOMAIN}" }
        end
      end

      private

      # +allocate+ skips the class's overridden +new+, so +initialize+ has to be invoked
      # explicitly. Every client instance in the library is built through here.
      def construct(klass, options)
        klass.allocate.tap { |client| client.send(:initialize, options) }
      end

      # @spec REC1b2
      def hostname_endpoint?(endpoint)
        endpoint.include?('.') || endpoint.include?('::') || endpoint == 'localhost'
      end

      def nonprod_endpoint?(endpoint)
        endpoint.start_with?(NONPROD_ENDPOINT_PREFIX)
      end

      def nonprod_endpoint_id(endpoint)
        endpoint.delete_prefix(NONPROD_ENDPOINT_PREFIX)
      end
    end
  end
end
