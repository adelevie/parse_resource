class ParseError
  # ParseError actually represents both HTTP & parse.com error codes. If the
  # HTTP response is 400, one can inspect the first element of the error
  # converted to_array for the HTTP error code and the 2nd element for the
  # parse error response.
  attr_accessor :msg, :code, :error
  
  # @param [String] an error code, e.g. "400"
  # @param [Object] an optional error mesg/object.
  def initialize(code, msg="")
    @msg = msg
    @code = code
    case code.to_s
    when "111"
      @error = "Invalid type."
    when "135"
      @error = "Unknown device type."
    when "202"
      @error = "Username already taken."
    when "400"
      @error = "Bad Request: The request cannot be fulfilled due to bad syntax."
    when "401"
      @error = "Unauthorized: Check your App ID & Master Key."
    when "403"
      @error = "Forbidden: You do not have permission to access or modify this."
    when "408"
      @error = "Request Timeout: The request was not completed within the time the server was prepared to wait."
    when "415"
      @error = "Unsupported Media Type"
    when "500"
      @error = "Internal Server Error"
    when "502"
      @error = "Bad Gateway"
    when "503"
      @error = "Service Unavailable"
    when "508"
      @error = "Loop Detected"
    else
      @error = "Unknown Error"
      raise "Parse error #{code}: #{@error} #{@msg}"
    end
  end
  
  def to_array
    [ @code, @msg ]
  end
  
end
