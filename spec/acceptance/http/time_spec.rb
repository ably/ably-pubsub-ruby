require 'spec_helper'

describe Ably::PubSub::Http::Client, '#time' do
  vary_by_protocol do
    let(:client) do
      Ably::Internal.create_http_client(key: api_key, environment: environment, protocol: protocol)
    end

    describe 'fetching the service time' do
      it 'should return the service time as a Time object' do
        expect(client.time).to be_within(2).of(Time.now)
      end

      context 'with reconfigured HTTP timeout' do
        let(:client) do
          Ably::Internal.create_http_client(http_request_timeout: 0.0001, key: api_key, environment: environment, protocol: protocol, log_retries_as_info: true)
        end

        it 'should raise a timeout exception' do
          expect { client.time }.to raise_error Ably::Exceptions::ConnectionTimeout
        end
      end
    end
  end
end
