require 'addressable/uri'

require 'ably/version'
require 'ably/agent'

%w(modules util).each do |namespace|
  Dir.glob(File.expand_path("ably/#{namespace}/*.rb", File.dirname(__FILE__))).sort.each do |file|
    require file
  end
end

require 'ably/auth'
require 'ably/pubsub'
require 'ably/exceptions'
require 'ably/logger'
require 'ably/pubsub/realtime'
require 'ably/pubsub/http'

# Requires the client classes above: it constructs them.
require 'ably/internal'
