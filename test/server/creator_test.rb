# frozen_string_literal: true
require_relative 'creator_test_base'

class CreatorTest < CreatorTestBase

  def self.id58_prefix
    :f26
  end

  # - - - - - - - - - - - - - - - - -
  # 200 OK
  # - - - - - - - - - - - - - - - - -

  qtest q31: %w(
  |POST /create_custom_group
  |with a valid display_name in the JSON-Request body
  |creates a group
  |whose manifest matches the display_name
  |whose id is in the JSON-Response body
  ) do
    json_post '/create_custom_group', args={
      display_name:any_custom_display_name
    }
    assert_status(SUCCESS)
    assert_group_exists(id_from_json_response, args[:display_name])
  end

  # - - - - - - - - - - - - - - - - -

  test 'q32', %w(
  POST /create_custom_kata,
  with a valid display_name in the JSON-Request body,
  creates a kata,
  whose manifest matches the display_name,
  whose id is in the JSON-Response body
  ) do
    json_post '/create_custom_kata', data = { display_name:any_custom_display_name }
    assert_status(SUCCESS)
    assert_kata_exists(id_from_json_response, data[:display_name])
  end

  # - - - - - - - - - - - - - - - - -
  # 500 Request Errors
  # - - - - - - - - - - - - - - - - -

  test 'Kp1', %w(
    POST /create_custom_group,
    with JSON-Hash Request.body containing unknown arg,
    ...
  ) do
    json_post '/create_custom_group', unknown_arg = '{"unknown":42}'
    assert_status(500)
  end

  # - - - - - - - - - - - - - - - - -

=begin # it seems for a GET, the body is moved to params!?

  test 'Kp2', %w(
    GET /sha,
    with non-JSON in Request.body,
    ...
  ) do
    unknown_arg = 'xyz'
    get '/sha', unknown_arg, JSON_REQUEST_HEADERS
    assert_status(500) # FAILS, ==200
    # params:{"xyz"=>nil}:
    # body::
  end
  
=end

  # - - - - - - - - - - - - - - - - -

  test 'Kp3', %w(
    POST /create_custom_group,
    with non-JSON Request.body,
    ...
  ) do
    json_post '/create_custom_group', non_json = 'xyz'
    assert_status(500)
    #...
  end

  # - - - - - - - - - - - - - - - - -

  test 'Kp4', %w(
    POST /create_custom_group,
    with non-JSON-Hash Request.body,
    ...
  ) do
    json_post '/create_custom_group', non_json_hash = 42
    assert_status(500)
    #...
  end

  # - - - - - - - - - - - - - - - - -

  test 'aX3', %w(
    POST /create_custom_group?display_name=INVALID,
    ...
  ) do
    post '/create_custom_group', data={ display_name:'invalid' }
    assert_status(500)
    # TODO response.body needs to get json { "exception":"...." }
  end

  # - - - - - - - - - - - - - - - - -

  test 'aX4', %w(
  POST /create_custom_group,
  with an invalid display_name in the JSON-Request body,
  ...
  ) do
    json_post '/create_custom_group', data = { display_name:'invalid' }
    assert_status(500)
    # TODO response.body needs to get json { "exception":"...." }
  end

  private

  def any_custom_display_name
    custom.display_names.sample
  end

  def assert_group_exists(id, display_name)
    refute_nil id, :id
    assert group_exists?(id), "!group_exists?(#{id})"
    manifest = group_manifest(id)
    assert_equal display_name, manifest['display_name'], manifest.keys.sort
  end

  def assert_kata_exists(id, display_name)
    refute_nil id, :id
    assert kata_exists?(id), "!kata_exists?(#{id})"
    manifest = kata_manifest(id)
    assert_equal display_name, manifest['display_name'], manifest.keys.sort
  end

  def group_manifest(id)
    JSON::parse!(saver.read("#{group_id_path(id)}/manifest.json"))
  end

  def kata_manifest(id)
    JSON::parse!(saver.read("#{kata_id_path(id)}/manifest.json"))
  end

  def id_from_group_url
    match = last_request.url.match(%r{http://example.org/kata/group/(.*)})
    assert match, "did not match #{last_request.url}"
    match[1]
  end

  def id_from_kata_url
    match = last_request.url.match(%r{http://example.org/kata/edit/(.*)})
    assert match, "did not match #{last_request.url}"
    match[1]
  end

  def id_from_json_response
    json_response[@path[1..-1]]
  end

  JSON_REQUEST_HEADERS = {
    'CONTENT_TYPE' => 'application/json',  # sent in request
    'HTTP_ACCEPT' => 'application/json'    # received in response
  }

  def json_post(path, data)
    @path = path
    post path, data.to_json, JSON_REQUEST_HEADERS
  end

end
