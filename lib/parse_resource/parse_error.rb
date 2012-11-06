class ParseError
  
  def initialize(code, msg="")
    @msg = msg
    case code
    when "111"
      @error = "Invalid type."
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
    @error[1] = @error[1] + " " + @msg
    @error
  end
  
end
