require_relative 'creator_test_base'
require_relative 'rack_request_stub'
require_relative '../rack_dispatcher'

class RackDispatcherTest < CreatorTestBase

  def self.hex_prefix
    '4AF'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 200
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '130', %w(
  allow empty json body '' instead of {} which is
  useful for kubernetes live/ready probes ) do
    response = rack_call('ready', '')
    assert_equal 200, response[0]
    assert_equal({ 'Content-Type' => 'application/json' }, response[1])
    assert_equal({"ready?" => true}, JSON.parse(response[2][0]))
  end

  test '131', '/sha 200' do
    assert_200('sha', args={}) do |response|
      assert_equal ENV['SHA'], response['sha']
    end
  end

  test '132', '/alive 200' do
    assert_200('alive', args={}) do |response|
      assert_equal true, response['alive?']
    end
  end

  test '133', '/ready 200' do
    assert_200('ready', args={}) do |response|
      assert_equal true, response['ready?']
    end
  end

  test '134', '/create_group 200' do
    manifest = any_manifest
    args = { manifest:manifest }
    assert_200('create_group', args) do |response|
      id = response['create_group']
      assert group_exists?(id), id
    end
  end

  test '135', '/create_kata 200' do
    manifest = any_manifest
    args = { manifest:manifest }
    assert_200('create_kata', args) do |response|
      id = response['create_kata']
      assert kata_exists?(id), id
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 400
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E2C',
  'dispatch returns 400 status when body is not JSON' do
    assert_dispatch_error('xyz', '123', 400, 'body is not JSON Hash')
  end

  test 'E2B',
  'dispatch returns 400 status when body is not JSON Hash' do
    assert_dispatch_error('xyz', [].to_json, 400, 'body is not JSON Hash')
  end

  test 'E2A',
  'dispatch returns 400 when path is unknown' do
    assert_dispatch_error('xyz', {}.to_json, 400, 'unknown path')
  end

  test '228',
  '/create_group returns 400 when manifest is missing' do
    assert_dispatch_error('create_group', {}.to_json, 400, 'manifest is missing')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 500
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  class CreatorShaRaiser
    def initialize(*args)
      @klass = args[0]
      @message = args[1]
    end
    def sha
      raise @klass, @message
    end
  end

  test 'F1A',
  'dispatch returns 500 status when implementation raises' do
    @creator = CreatorShaRaiser.new(ArgumentError, 'wibble')
    assert_dispatch_error('sha', {}.to_json, 500, 'wibble')
  end

  test 'F1B',
  'dispatch returns 500 status when implementation has syntax error' do
    @creator = CreatorShaRaiser.new(SyntaxError, 'fubar')
    assert_dispatch_error('sha', {}.to_json, 500, 'fubar')
  end

  private

  def assert_200(name, args)
    response = rack_call(name, args.to_json)
    assert_equal 200, response[0]
    assert_equal({ 'Content-Type' => 'application/json' }, response[1])
    yield JSON.parse(response[2][0])
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_dispatch_error(name, args, status, message)
    @creator ||= Object.new
    response,stderr = with_captured_stderr { rack_call(name, args) }
    assert_equal status, response[0], "message:#{message},stderr:#{stderr}"
    assert_equal({ 'Content-Type' => 'application/json' }, response[1])
    assert_json_exception(response[2][0], name, args, message)
    assert_json_exception(stderr,         name, args, message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_json_exception(s, name, body, message)
    json = JSON.parse!(s)
    exception = json['exception']
    refute_nil exception
    diagnostic = "path:#{__LINE__}"
    assert_equal '/'+name, exception['path'], diagnostic
    diagnostic = "body:#{__LINE__}"
    assert_equal body, exception['body'], diagnostic
    diagnostic = "exception['class']:#{__LINE__}"
    assert_equal 'CreatorService', exception['class'], diagnostic
    diagnostic = "exception['message']:#{__LINE__}"
    assert_equal message, exception['message'], diagnostic
    diagnostic = "exception['backtrace'].class.name:#{__LINE__}"
    assert_equal 'Array', exception['backtrace'].class.name, diagnostic
    diagnostic = "exception['backtrace'][0].class.name:#{__LINE__}"
    assert_equal 'String', exception['backtrace'][0].class.name, diagnostic
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def rack_call(name, args)
    @creator ||= Creator.new(externals)
    rack = RackDispatcher.new(@creator, RackRequestStub)
    env = { path_info:name, body:args }
    rack.call(env)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def with_captured_stderr
    old_stderr = $stderr
    $stderr = StringIO.new('', 'w')
    response = yield
    return [ response, $stderr.string ]
  ensure
    $stderr = old_stderr
  end

end