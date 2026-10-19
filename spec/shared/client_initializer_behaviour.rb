# encoding: utf-8

shared_examples 'a client initializer' do
  def protocol
    if rest?
      'http'
    else
      'ws'
    end
  end

  def rest?
    subject.kind_of?(Ably::PubSub::Http::Client)
  end

  context 'with invalid arguments' do
    context 'empty hash' do
      let(:client_options) { Hash.new }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is missing/)
      end
    end

    context 'nil' do
      let(:client_options) { nil }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /Options Hash is expected/)
      end
    end

    context 'key: "invalid"' do
      let(:client_options) { { key: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is invalid/)
      end
    end

    context 'key: "invalid:asdad"' do
      let(:client_options) { { key: 'invalid:asdad' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is invalid/)
      end
    end

    context 'key and key_name' do
      let(:client_options) { { key: 'appid.keyuid:keysecret', key_name: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key and key_name or key_secret are mutually exclusive/)
      end
    end

    context 'key and key_secret' do
      let(:client_options) { { key: 'appid.keyuid:keysecret', key_secret: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key and key_name or key_secret are mutually exclusive/)
      end
    end
  end

  context 'with valid arguments' do
    let(:default_options) { { key: 'appid.keyuid:keysecret', auto_connect: false } }
    let(:client_options)  { default_options }

    context 'key only' do
      it 'connects to the Ably service' do
        expect { subject }.to_not raise_error
      end

      it 'uses basic auth' do
        expect(subject.auth).to be_using_basic_auth
      end
    end

    context 'key_name and key_secret', api_private: true do
      let(:client_options) { { key_name: 'id', key_secret: 'secret', auto_connect: false } }

      it 'constructs a key' do
        expect(subject.auth.key).to eql('id:secret')
      end
    end

    context 'with a string key instead of options hash' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      let(:client_options) { 'App.k3y:sec-r3t' }

      it 'sets the key' do
        expect(subject.auth.key).to eql(client_options)
      end

      it 'sets the key_name' do
        expect(subject.auth.key_name).to eql('App.k3y')
      end

      it 'sets the key_secret' do
        expect(subject.auth.key_secret).to eql('sec-r3t')
      end

      it 'uses basic auth' do
        expect(subject.auth).to be_using_basic_auth
      end
    end

    context 'with a string token key instead of options hash' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      let(:client_options) { 'app.kjhkasjhdsakdh127g7g1271' }

      it 'sets the token' do
        expect(subject.auth.current_token_details.token).to eql(client_options)
      end
    end

    context 'with token' do
      let(:client_options) { { token: 'token', auto_connect: false } }

      it 'sets the token' do
        expect(subject.auth.current_token_details.token).to eql('token')
      end
    end

    context 'with token_details' do
      let(:client_options) { { token_details: Ably::Models::TokenDetails.new(token: 'token'), auto_connect: false } }

      it 'sets the token' do
        expect(subject.auth.current_token_details.token).to eql('token')
      end
    end

    context 'with token_params' do
      let(:client_options) { { default_token_params: { ttl: 777, client_id: 'john' }, token: 'token', auto_connect: false } }

      it 'configures default_token_params' do
        expect(subject.auth.token_params.fetch(:ttl)).to eql(777)
        expect(subject.auth.token_params.fetch(:client_id)).to eql('john')
      end
    end

    context 'endpoint (#REC1)' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      it 'defaults to main' do
        expect(subject.endpoint).to eql('main')
      end

      it 'uses the main production primary domain (#REC1a)' do
        expect(subject.primary_domain).to eql('main.realtime.ably.net')
        expect(subject.uri.to_s).to eql("#{protocol}s://main.realtime.ably.net")
      end

      context 'with a routing policy name' do
        let(:client_options) { default_options.merge(endpoint: 'acme') }

        it 'uses the production primary domain for that routing policy (#REC1b4)' do
          expect(subject.primary_domain).to eql('acme.realtime.ably.net')
          expect(subject.uri.to_s).to eql("#{protocol}s://acme.realtime.ably.net")
        end
      end

      context 'with a nonprod routing policy name' do
        let(:client_options) { default_options.merge(endpoint: 'nonprod:sandbox') }

        it 'uses the non-production primary domain for that routing policy (#REC1b3)' do
          expect(subject.primary_domain).to eql('sandbox.realtime.ably-nonprod.net')
          expect(subject.uri.to_s).to eql("#{protocol}s://sandbox.realtime.ably-nonprod.net")
        end
      end

      %w(foo.example.com localhost 127.0.0.1 ::1).each do |hostname|
        context "with hostname #{hostname}" do
          let(:client_options) { default_options.merge(endpoint: hostname) }

          it 'uses the hostname as the primary domain (#REC1b2)' do
            expect(subject.primary_domain).to eql(hostname)
          end
        end
      end

      context 'with port option and non-TLS connections' do
        let(:client_options) { default_options.merge(port: 999, tls: false, auto_connect: false) }

        it 'uses the custom port for non-TLS requests' do
          expect(subject.uri.to_s).to include(":999")
        end
      end

      context 'with tls_port option and a TLS connection' do
        let(:client_options) { default_options.merge(tls_port: 666, tls: true, auto_connect: false) }

        it 'uses the custom port for TLS requests' do
          expect(subject.uri.to_s).to include(":666")
        end
      end
    end

    context 'tls' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      context 'set to false' do
        let(:client_options) { default_options.merge(tls: false, auto_connect: false) }

        it 'uses plain text' do
          expect(subject.use_tls?).to eql(false)
        end

        it 'uses HTTP' do
          expect(subject.uri.to_s).to eql("#{protocol}://main.realtime.ably.net")
        end
      end

      it 'defaults to TLS' do
        expect(subject.use_tls?).to eql(true)
      end
    end

    context 'logger' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      context 'default' do
        it 'uses Ruby Logger' do
          expect(subject.logger.logger).to be_a(::Logger)
        end

        it 'specifies Logger::WARN log level' do
          expect(subject.logger.log_level).to eql(::Logger::WARN)
        end
      end

      context 'with log_level :none' do
        let(:client_options) { default_options.merge(log_level: :none, auto_connect: false) }

        it 'silences all logging with a NilLogger' do
          expect(subject.logger.logger.class).to eql(Ably::Models::NilLogger)
          expect(subject.logger.log_level).to eql(:none)
        end
      end

      context 'with custom logger and log_level' do
        let(:custom_logger) { TestLogger }
        let(:client_options) { default_options.merge(logger: custom_logger.new, log_level: Logger::DEBUG, auto_connect: false) }

        it 'uses the custom logger' do
          expect(subject.logger.logger.class).to eql(custom_logger)
        end

        it 'sets the custom log level' do
          expect(subject.logger.log_level).to eql(Logger::DEBUG)
        end
      end
    end

    context 'fallback hosts (#REC2)' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      it 'defaults to the main production fallback hosts (#REC2c1)' do
        expect(subject.fallback_hosts.sort).to eql(%w(a b c d e).map { |id| "main.#{id}.fallback.ably-realtime.com" })
        expect(subject.fallback_hosts.sort).to eql(Ably::FALLBACK_HOSTS)
      end

      context 'with a routing policy name' do
        let(:client_options) { default_options.merge(endpoint: 'acme') }

        it 'uses the production fallback hosts for that routing policy (#REC2c4)' do
          expect(subject.fallback_hosts.sort).to eql(%w(a b c d e).map { |id| "acme.#{id}.fallback.ably-realtime.com" })
        end
      end

      context 'with a nonprod routing policy name' do
        let(:client_options) { default_options.merge(endpoint: 'nonprod:sandbox') }

        it 'uses the non-production fallback hosts for that routing policy (#REC2c3)' do
          expect(subject.fallback_hosts.sort).to eql(%w(a b c d e).map { |id| "sandbox.#{id}.fallback.ably-realtime-nonprod.com" })
        end
      end

      %w(foo.example.com localhost 127.0.0.1 ::1).each do |hostname|
        context "with hostname #{hostname}" do
          let(:client_options) { default_options.merge(endpoint: hostname) }

          it 'has no default fallback hosts (#REC2c2)' do
            expect(subject.fallback_hosts).to be_empty
          end
        end
      end

      context 'with custom fallback hosts configured' do
        let(:custom_fallbacks) { %w(a b c).map { |id| "#{id}.foo.com" } }

        %w(main nonprod:sandbox foo.example.com).each do |endpoint_value|
          context "and endpoint #{endpoint_value}" do
            let(:client_options) { default_options.merge(endpoint: endpoint_value, fallback_hosts: custom_fallbacks) }

            it 'uses the custom provided fallback hosts (#REC2a2)' do
              expect(subject.fallback_hosts.sort).to eql(custom_fallbacks)
            end
          end
        end
      end

      context 'with an empty fallback hosts list' do
        let(:client_options) { default_options.merge(fallback_hosts: []) }

        it 'has no fallback hosts' do
          expect(subject.fallback_hosts).to be_empty
        end
      end

      context 'with a custom port' do
        let(:client_options) { default_options.merge(port: 555) }

        it 'uses the default fallback hosts' do
          expect(subject.fallback_hosts.sort).to eql(Ably::FALLBACK_HOSTS)
        end
      end

      context 'with a custom TLS port' do
        let(:client_options) { default_options.merge(tls_port: 555) }

        it 'uses the default fallback hosts' do
          expect(subject.fallback_hosts.sort).to eql(Ably::FALLBACK_HOSTS)
        end
      end
    end
  end

  context 'delegators' do
    before do
      allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
    end

    let(:client_options) { 'app.key:secret' }

    it 'delegates :client_id to .auth' do
      expect(subject.auth).to receive(:client_id).and_return('john')
      expect(subject.client_id).to eql('john')
    end

    it 'delegates :auth_options to .auth' do
      expect(subject.auth).to receive(:auth_options).and_return({ option: 1 })
      expect(subject.auth_options).to eql({ option: 1 })
    end
  end
end
