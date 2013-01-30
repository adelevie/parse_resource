class ParseError
  # ParseError actually represents both HTTP & parse.com error codes. If the
  # HTTP response is 400, one can inspect the first element of the error
  # converted to_array for the HTTP error code and the 2nd element for the
  # parse error response.
  
  # @param [String] an error code, e.g. "400"
  # @param [Object] an optional error mesg/object.
  def initialize(code, msg="")
    @msg = msg
    @code = code
    case code
    when "400"
      if msg.empty?
        @msg = "Bad Request: The request cannot be fulfilled due to bad syntax."
      end
      # otherwise we should have supplied the Parse msg JSON response.
    when "401"
      @msg = "Unauthorized: Check your App ID & Master Key."
    when "403"
      @msg = "Forbidden: You do not have permission to access or modify this."
    when "408"
      @msg = "Unsupported Media Type"
    when "500"
      @msg = "Internal Server Error"
    when "502"
      @msg = "Bad Gateway"
    when "503"
      @msg = "Service Unavailable"
    when "508"
      @msg = "Loop Detected"
    else
      @msg = "Unknown Error"
      raise "Parse msg #{code}: #{@error}"
    end
  end
  
  def to_array
    return [@code, @msg]
  end
  
end
