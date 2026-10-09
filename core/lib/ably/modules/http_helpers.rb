require 'base64'

require 'ably/version'

require 'ably/pubsub/http/middleware/encoder'
require 'ably/pubsub/http/middleware/external_exceptions'
require 'ably/pubsub/http/middleware/fail_if_unsupported_mime_type'
require 'ably/pubsub/http/middleware/logger'
require 'ably/pubsub/http/middleware/parse_json'
require 'ably/pubsub/http/middleware/parse_message_pack'

module Ably::Modules
  # HttpHelpers provides common private methods to classes to simplify HTTP interactions with Ably
  module HttpHelpers
    protected
    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end

    def user_agent
      "Ably Ruby client #{Ably::VERSION} (https://www.ably.io)"
    end

    def setup_outgoing_middleware(builder)
      # Convert request params to "www-form-urlencoded"
      builder.use Ably::PubSub::Http::Middleware::Encoder
    end

    def setup_incoming_middleware(builder, logger, options = {})
      builder.use Ably::PubSub::Http::Middleware::Logger, logger

      # Parse JSON / MsgPack response bodies. ParseJson must be first (default) parsing middleware
      if options[:fail_if_unsupported_mime_type] == true
        builder.use Ably::PubSub::Http::Middleware::FailIfUnsupportedMimeType
      end

      builder.use Ably::PubSub::Http::Middleware::ParseJson
      builder.use Ably::PubSub::Http::Middleware::ParseMessagePack
    end
  end
end
