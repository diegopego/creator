# frozen_string_literal: true
require_relative 'creator_test_base'
require 'json'

class CreateKataTest < CreatorTestBase

  def self.id58_prefix
    'p43'
  end

  def id58_setup
    @exercise_name = exercises_start_points.display_names.sample
    @display_name = custom_start_points.display_names.sample
    @language_name = languages_start_points.display_names.sample
  end

  attr_reader :exercise_name, :display_name, :language_name

  # - - - - - - - - - - - - - - - - -

  test 'w9A', %w(
  |POST /create.json
  |with [type=single,exercise_name,language_name] URL params
  |generates json route /creator/enter?id=ID page
  |and a kata-exercise with ID exists
  ) do
    json_post_create({
      type:'single',
      exercise_name:exercise_name,
      language_name:language_name
    }) do |manifest|
      assert_equal language_name, manifest['display_name'], manifest
      assert_equal exercise_name, manifest['exercise'], manifest
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'w9B', %w(
  |POST /create.json
  |with [type=single,language_name] URL params
  |generates json route /creator/enter?id=ID page
  |and a kata-exercise with ID exists
  ) do
    json_post_create({
      type:'single',
      language_name:language_name
    }) do |manifest|
      assert_equal language_name, manifest['display_name'], manifest
      refute manifest.has_key?('exercise'), :skipped_exercise
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'w9C', %w(
  |POST /create.json
  |with [type=single,display_name] URL params
  |generates json route /creator/enter?id=ID page
  |and a kata-exercise with ID exists
  ) do
    json_post_create({
      type:'single',
      display_name:display_name
    }) do |manifest|
      assert_equal display_name, manifest['display_name'], manifest
      refute manifest.has_key?('exercise'), :custom_problem
    end
  end

  private

  def json_post_create(args)
    json_post '/create.json', args
    route = json_response['route'] # eg "/creator/enter?id=xCSKgZ"
    assert %r"/creator/enter\?id=(?<id>.*)" =~ route, route
    assert kata_exists?(id), "id:#{id}:" # eg "xCSKgZ"
    yield kata_manifest(id)
  end

end
