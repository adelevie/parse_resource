class Cloud
  attr_accessor :function_name

  def initialize(function_name)
    @function_name = function_name
  end

  def uri
    # Protocol.cloud_function_uri(@function_name)
  end

  def call(params={})
    response = @function_name.resource.get(:params => params.to_json)
    # response = Parse.client.post(self.uri, params.to_json)
    result = response["result"]
    result
  end

end
