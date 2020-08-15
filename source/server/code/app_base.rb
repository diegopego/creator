# frozen_string_literal: true
require_relative 'silently'
require 'json'
require 'sinatra/base'
silently { require 'sinatra/contrib' } # N x "warning: method redefined"
require_relative 'http_json_hash/service'

class AppBase < Sinatra::Base

  silently { register Sinatra::Contrib }
  set :port, ENV['PORT']

  def initialize
    super(nil)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.get_probe(name)
    get "/#{name}" do
      result = instance_eval { target.public_send(name) }
      json({ name => result })
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.post_json(name)
    post "/#{name}", provides:[:json] do
      respond_to do |format|
        format.json {
          result = instance_eval {
            target.public_send(name, **json_args)
          }
          json({ name => result })
        }
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.deprecated_post_json(name)
    post "/#{name}", provides:[:json] do
      respond_to do |format|
        format.json {
          result = instance_eval {
            target.public_send(name, **json_args)
          }
          backwards_compatible = { id:result }
          json backwards_compatible.merge({name => result})
        }
      end
    end
  end

  private

  def json_args
    symbolized(json_payload)
  end

  def symbolized(h)
    # named-args require symbolization
    h.transform_keys! { |key| key.to_sym }
  end

  def json_payload
    json_hash_parse(request.body.read)
  end

  def json_hash_parse(body)
    json = (body === '') ? {} : JSON.parse!(body)
    unless json.instance_of?(Hash)
      fail 'body is not JSON Hash'
    end
    json
  rescue JSON::ParserError
    fail 'body is not JSON'
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  set :show_exceptions, false

  error do
    error = $!
    status(500)
    content_type('application/json')
    info = {
      exception: {
        request: {
          path:request.path,
          body:request.body.read
        },
        backtrace: error.backtrace
      }
    }
    exception = info[:exception]
    if error.instance_of?(::HttpJsonHash::ServiceError)
      exception[:http_service] = {
        path:error.path,
        args:error.args,
        name:error.name,
        body:error.body,
        message:error.message
      }
    else
      exception[:message] = error.message
    end
    diagnostic = JSON.pretty_generate(info)
    puts diagnostic
    body diagnostic
  end

end