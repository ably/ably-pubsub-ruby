# encoding: utf-8
require 'spec_helper'

describe Ably::Rest do
  let(:options) { { key: 'app.key:secret' } }

  # This was a convenience alias for the Ably::Rest::Client constructor. It now refuses,
  # because a client's side is declared by the package it was created from.
  specify 'constructor refuses and points at the factory function' do
    expect { Ably::Rest.new(options) }
      .to raise_error(Ably::Exceptions::DirectConstructionNotSupported, /create_http_client/)
  end
end
