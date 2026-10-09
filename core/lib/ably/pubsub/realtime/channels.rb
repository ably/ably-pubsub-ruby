module Ably
  module PubSub
    module Realtime
      # Class that maintains a map of Channels ensuring Channels are reused
      class Channels
        include Ably::Modules::ChannelsCollection

        # @return [Ably::PubSub::Realtime::Channels]
        #
        def initialize(client)
          super client, Ably::PubSub::Realtime::Channel
        end

        # Return a {Ably::PubSub::Realtime::Channel} for the given name
        #
        # @param name [String] The name of the channel
        # @param channel_options [Hash, Ably::Models::ChannelOptions] A hash of options or a {Ably::Models::ChannelOptions}
        #
        # @return [Ably::PubSub::Realtime::Channel]
        #
        def get(*args)
          super
        end

        # Return a {Ably::PubSub::Realtime::Channel} for the given name if it exists, else the block will be called.
        # This method is intentionally similar to {http://ruby-doc.org/core-2.1.3/Hash.html#method-i-fetch Hash#fetch} providing a simple way to check if a channel exists or not without creating one
        #
        # @param name [String] The name of the channel
        # @yield [options] (optional) if a missing_block is passed to this method and no channel exists matching the name, this block is called
        # @yieldparam [String] name of the missing channel
        #
        # @return [Ably::PubSub::Realtime::Channel]
        #
        def fetch(*args)
          super
        end

        # Releases the {Ably::PubSub::Realtime::Channel Realtime Channel} with the given name and all associated resources.
        #
        # Releasing a Realtime Channel is not typically necessary as a channel, once detached, consumes no resources other than
        # the memory footprint of the {Ably::PubSub::Realtime::Channel Realtime Channel object}. Release channels to free up resources if required
        #
        # A realtime channel can only be released when it is in the +INITIALIZED+, +DETACHED+, or +FAILED+ state.
        #
        # @spec RTS4c, RTS4d, RTS4e
        #
        # @param channel [String] The name of the channel
        #
        # @raise [Ably::Exceptions::InvalidState] if the channel is not in the +INITIALIZED+, +DETACHED+, or +FAILED+ state
        #
        # @return [void]
        #
        def release(channel)
          return unless @channels.has_key?(channel)

          released_channel = get(channel)
          unless released_channel.initialized? || released_channel.detached? || released_channel.failed?
            raise Ably::Exceptions::InvalidState.new(
              "Can only release a channel in a state where there is no possibility of further updates from the server being received " \
                "(initialized, detached, or failed). The current state is #{released_channel.state.to_sym}",
              400,
              90011
            )
          end

          @channels.delete(channel)
          nil
        end

        # Sets channel serial to each channel from given serials hashmap
        # @param [Hash] serials - map of channel name to respective channel serial
        # @api private
        def set_channel_serials(serials)
          serials.each do |channel_name, channel_serial|
            get(channel_name).properties.channel_serial = channel_serial
          end
        end

        # @return [Hash] serials - map of channel name to respective channel serial
        # @api private
        def get_channel_serials
          channel_serials = {}
          self.each do |channel|
            channel_serials[channel.name] = channel.properties.channel_serial if channel.state == :attached
          end
          channel_serials
        end

      end
    end
  end
end
