# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLVerify < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  CERT_FROM_FILE = File.read "#{__dir__}/client.crt"

  CLIENT_CERT = { private_key_file: "#{__dir__}/client.key",
                  cert_chain_file:  "#{__dir__}/client.crt" }

  def test_fail_no_peer_cert
    omit_if(rbx?)

    server = { verify_peer: true, fail_if_no_peer_cert: true,
      ssl_verify_result: "|RAISE|Verify peer should not get called for a client without a certificate" }

    client_server Client, Server, server: server

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_accept_server
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: CLIENT_CERT, server: server

    assert_equal CERT_FROM_FILE, Server.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_deny_server
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, client: CLIENT_CERT, server: server

    assert_equal CERT_FROM_FILE, Server.cert
    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end
end if EM.ssl?
