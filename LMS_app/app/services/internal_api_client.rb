class InternalApiClient
  class RequestError < StandardError; end

  def initialize(base_url:, access_token:)
    @connection = Faraday.new(url: base_url) do |faraday|
      faraday.headers['Authorization'] = "Bearer #{access_token}"
      faraday.headers['Content-Type'] = 'application/json'
      faraday.adapter Faraday.default_adapter
    end
  end

  def get(path, params = {})
    response = @connection.get(path, params)

    unless response.success?
      raise RequestError, "GET #{path} failed with status #{response.status}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise RequestError, "Invalid JSON response for GET #{path}: #{e.message}"
  end
end
