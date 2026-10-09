# Ably is the base namespace for the Ably {Ably::PubSub::Realtime Realtime} & {Ably::PubSub::Http Rest} client libraries.
#
# Please refer to the {file:README.md Readme} on getting started.
#
# @see file:README.md README
module Ably
  # Default routing policy used when the +:endpoint+ client option is not provided
  # @spec REC1a
  ENDPOINT = 'main'.freeze

  PROD_ROOT_DOMAIN = 'ably.net'.freeze
  PROD_FALLBACK_DOMAIN = 'ably-realtime.com'.freeze

  # Fallback hosts are used when a connection to the primary domain is not possible due to
  # network failures either at the client, between the client and Ably, within an Ably data center, or at the domain registrar
  # see https://ably.com/docs/client-lib-development-guide/features/#RSC15a
  FALLBACK_IDS = %w(a b c d e).freeze

  # Default production fallbacks main.a.fallback.ably-realtime.com ... main.e.fallback.ably-realtime.com
  # @spec REC2c1
  FALLBACK_HOSTS = FALLBACK_IDS.map { |id| "#{ENDPOINT}.#{id}.fallback.#{PROD_FALLBACK_DOMAIN}".freeze }.freeze

  INTERNET_CHECK = {
    url:     '//internet-up.ably-realtime.com/is-the-internet-up.txt',
    ok_text: 'yes'
  }.freeze
end
