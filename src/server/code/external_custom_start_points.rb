# frozen_string_literal: true
require_relative 'http_json_hash/service'

class ExternalCustomStartPoints

  class Error < RuntimeError
    def initialize(message)
      super
    end
  end

  def initialize(http)
    @http = HttpJsonHash::service(http, 'custom-start-points', 4526, Error)
  end

  def ready?
    @http.get(__method__, {})
  end

  def display_names
    @http.get(:names, {})
  end

  def manifest(display_name)
    @http.get(__method__, { name:display_name })
  end

end
