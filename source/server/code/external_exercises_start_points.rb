require_relative 'http_json_hash/service'

class ExternalExercisesStartPoints

  def initialize(http)
    name = 'exercises-start-points'
    port = ENV['CYBER_DOJO_EXERCISES_START_POINTS_PORT'].to_i
    @http = HttpJsonHash::service(self.class.name, http, name, port)
  end

  def ready?
    @http.get(__method__, {})
  end

  def display_names
    @http.get(:names, {})
  end

  def manifests
    @http.get(:manifests, {})
  end

end
