# encoding: utf-8
require 'spec_helper'
require 'ably/pubsub/server'

# A client's side is declared by the package it was created from, so a client constructed
# directly declares none and the platform cannot classify it for MAU billing. The classes
# therefore refuse direct construction, and the per-side packages construct through
# Ably::Internal instead. These specs guard both halves: the refusals must stay in place,
# and the internal entry points must keep producing usable clients. The Ably::PubSub::Http and
# Ably::PubSub::Realtime module aliases refuse too, covered in their own module specs.
describe 'direct construction' do
  let(:api_key) { 'appid.keyuid:keysecret' }

  refused = {
    'Ably::PubSub::Http::Client.new'     => -> (key) { Ably::PubSub::Http::Client.new(key) },
    'Ably::PubSub::Realtime::Client.new' => -> (key) { Ably::PubSub::Realtime::Client.new(key) },
  }

  refused.each do |subject_name, construct|
    describe subject_name do
      it 'raises DirectConstructionNotSupported' do
        expect { construct.call(api_key) }
          .to raise_error(Ably::Exceptions::DirectConstructionNotSupported)
      end

      it 'names itself and points at a factory function' do
        expect { construct.call(api_key) }.to raise_error do |error|
          expect(error.message).to include(subject_name)
          expect(error.message).to match(/Ably::PubSub::Server\.create_(http|realtime)_client/)
        end
      end

      # Hash and String options take different paths through the constructors, and a
      # refusal that only covered one of them would leave the other reachable.
      it 'raises for Hash options too' do
        expect { construct.call(key: api_key) }
          .to raise_error(Ably::Exceptions::DirectConstructionNotSupported)
      end
    end
  end

  describe 'Ably::Internal' do
    it 'creates a usable REST client' do
      client = Ably::Internal.create_http_client(key: api_key)
      expect(client).to be_a(Ably::PubSub::Http::Client)
      expect(client.auth.key).to eql(api_key)
    end

    it 'creates a usable realtime client' do
      client = Ably::Internal.create_realtime_client(key: api_key, auto_connect: false)
      expect(client).to be_a(Ably::PubSub::Realtime::Client)
      expect(client.rest_client).to be_a(Ably::PubSub::Http::Client)
    end

    # The realtime client builds its own REST client; if that call went back through the
    # public constructor, every realtime client would fail to build.
    it 'is what the realtime client uses to build its REST client' do
      expect(Ably::Internal).to receive(:create_http_client).once.and_call_original
      Ably::Internal.create_realtime_client(key: api_key, auto_connect: false)
    end

    it 'declares no side of its own' do
      client = Ably::Internal.create_http_client(key: api_key)
      expect(client.agent).to_not include(Ably::PubSub::Server::SERVER_AGENT_IDENTIFIER)
    end
  end

  # The whole point of the refusal: the supported path still works, and carries the side.
  describe 'the supported path' do
    it 'creates an HTTP client declaring the server side' do
      client = Ably::PubSub::Server.create_http_client(api_key)
      expect(client.agent).to include(Ably::PubSub::Server::SERVER_AGENT_IDENTIFIER)
    end

    it 'creates a realtime client declaring the server side' do
      client = Ably::PubSub::Server.create_realtime_client(key: api_key, auto_connect: false)
      expect(client.rest_client.agent).to include(Ably::PubSub::Server::SERVER_AGENT_IDENTIFIER)
    end
  end
end
