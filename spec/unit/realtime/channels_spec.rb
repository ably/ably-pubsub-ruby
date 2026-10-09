# encoding: utf-8
require 'spec_helper'

describe Ably::PubSub::Realtime::Channels do
  let(:connection) { instance_double('Ably::PubSub::Realtime::Connection', unsafe_on: true) }
  let(:client) do
    instance_double('Ably::PubSub::Realtime::Client', connection: connection, client_id: 'clientId', logger: double('logger').as_null_object)
  end
  let(:channel_name) { 'unique' }
  let(:options) do
    { params: { bizarre: 'value' } }
  end

  subject { Ably::PubSub::Realtime::Channels.new(client) }

  context 'creating channels' do
    context '#get' do
      context "when channel doesn't exist" do
        shared_examples 'creates a channel' do
          it 'creates a channel (RTS3a)' do
            expect(Ably::PubSub::Realtime::Channel).to receive(:new).with(client, channel_name, channel_options)
            subject.get(channel_name, channel_options)
          end
        end

        describe 'hash' do
          let(:channel_options) { options }
          it { expect(channel_options).to be_a(Hash) }

          include_examples 'creates a channel'
        end

        describe 'ChannelOptions object' do
          let(:channel_options) { Ably::Models::ChannelOptions.new(options) }
          it { expect(channel_options).to be_a(Ably::Models::ChannelOptions) }

          include_examples 'creates a channel'
        end
      end

      context 'when an existing channel exists' do
        shared_examples 'reuse a channel object if it exists' do
          it 'will reuse a channel object if it exists (RTS3a)' do
            channel = subject.get(channel_name, channel_options)
            expect(channel).to be_a(Ably::PubSub::Realtime::Channel)
            expect(subject.get(channel_name, channel_options).object_id).to eql(channel.object_id)
          end
        end

        describe 'hash' do
          let(:channel_options) { options }
          it { expect(channel_options).to be_a(Hash) }

          include_examples 'reuse a channel object if it exists'
        end

        describe 'ChannelOptions object' do
          let(:channel_options) { Ably::Models::ChannelOptions.new(options) }
          it { expect(channel_options).to be_a(Ably::Models::ChannelOptions) }

          include_examples 'reuse a channel object if it exists'
        end

        it 'will update the options on the channel if provided (RSN3c)' do
          channel = subject.get(channel_name, options)
          expect(channel.options.to_h).to eq(options)
          expect(channel.options.to_h).to_not include(:encrypted)
          subject.get(channel_name, encrypted: true)
          expect(channel.options[:encrypted]).to eq(true)
        end

        it 'will leave the options intact on the channel if not provided' do
          channel = subject.get(channel_name, options)
          expect(channel.options.to_h).to eq(options)
          subject.get(channel_name)
          expect(channel.options.to_h).to eq(options)
        end
      end
    end

    it '[] creates a channel' do
      expect(Ably::PubSub::Realtime::Channel).to receive(:new).with(client, channel_name, options)
      subject.get(channel_name, options)
    end
  end

  context '#fetch' do
    it 'retrieves a channel if it exists' do
      channel = subject.get(channel_name, options)
      expect(subject.fetch(channel_name)).to eql(channel)
    end

    it 'calls the block if channel is missing' do
      block_called = false
      subject.fetch(channel_name) { block_called = true }
      expect(block_called).to eql(true)
    end
  end

  context 'destroying channels' do
    let(:released_channel) { subject.get(channel_name, options) }

    def stub_state(state)
      allow(released_channel).to receive(:state).and_return(Ably::PubSub::Realtime::Channel::STATE(state))
    end

    it '#release does nothing if the channel does not exist (RTS4c)' do
      expect { subject.release(channel_name) }.to_not raise_error
      expect(subject.length).to eql(0)
    end

    [:initialized, :detached, :failed].each do |state|
      it "#release releases a channel in the #{state} state without detaching (RTS4d)" do
        stub_state state
        expect(released_channel).to_not receive(:detach)
        subject.release(channel_name)
        expect(subject.fetch(channel_name) { nil }).to be_nil
      end
    end

    [:attaching, :attached, :detaching, :suspended].each do |state|
      it "#release raises 90011 and leaves a channel in the #{state} state untouched (RTS4e)" do
        stub_state state
        expect(released_channel).to_not receive(:detach)
        expect { subject.release(channel_name) }.to raise_error(Ably::Exceptions::InvalidState) do |error|
          expect(error.code).to eql(90011)
          expect(error.status).to eql(400)
          expect(error.message).to match(/The current state is #{state}/)
        end
        expect(subject.fetch(channel_name)).to equal(released_channel)
      end
    end
  end

  context 'is Enumerable' do
    let(:channel_count) { 5 }
    let(:mock_channel)  { instance_double('Ably::PubSub::Realtime::Channel') }

    before do
      allow(Ably::PubSub::Realtime::Channel).to receive(:new).and_return(mock_channel)
      channel_count.times { |index| subject.get("channel-#{index}") }
    end

    it 'allows enumeration' do
      expect(subject.map.count).to eql(channel_count)
    end

    context '#each' do
      it 'returns an enumerator' do
        expect(subject.each).to be_a(Enumerator)
      end

      it 'yields each channel' do
        subject.each do |channel|
          expect(channel).to eql(mock_channel)
        end
      end
    end

    it 'provides #length' do
      expect(subject.length).to eql(channel_count)
    end
  end
end
