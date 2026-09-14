require 'spec_helper'

describe Ably::Realtime do
  let(:options) { { key: 'app.key:secret', auto_connect: false } }

  # This was a convenience alias for the Ably::Realtime::Client constructor. It now
  # refuses, because a client's side is declared by the package it was created from.
  specify 'constructor refuses and points at the factory function' do
    expect { Ably::Realtime.new(options) }
      .to raise_error(Ably::Exceptions::DirectConstructionNotSupported, /create_realtime_client/)
  end
end
