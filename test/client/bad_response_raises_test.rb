# frozen_string_literal: true
require_relative 'creator_test_base'
require 'ostruct'

class BadResponseRaisesTest < CreatorTestBase

  def self.id58_prefix
    '20F'
  end

  # - - - - - - - - - - - - - - - - -

  test '34a',
  %w( http body not JSON raises ) do
    creator_http_stub('{42:"sd"}')
    error = assert_raises(HttpJsonHash::ServiceError) { creator.ready? }
    expected = 'body is not JSON'
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - -

  test '34b',
  %w( http body not JSON Hash raises ) do
    creator_http_stub('42')
    error = assert_raises(HttpJsonHash::ServiceError) { creator.ready? }
    expected = 'body is not JSON Hash'
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - -

  test '34c',
  %w( http body JSON without key for method name raises ) do
    creator_http_stub('{}')
    error = assert_raises(HttpJsonHash::ServiceError) { creator.ready? }
    expected = 'body is missing :path key'
    assert_equal expected, error.message
  end

end
