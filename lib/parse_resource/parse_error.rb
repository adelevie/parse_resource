class ParseError
  
  def initialize(code, msg="")
    @msg = msg
    case code
    when 202
      @error = [:username, "must be unique"]
    when 111
      @error = [:base, "field set to incorrect type. Error code #{code}. #{msg}"]
    when 125
      @error = [:email, "must be valid"]
    when 122
      @error = [:file_name, "contains only a-zA-Z0-9_. characters and is between 1 and 36 characters."]
    when 204
      @error = [:email, "must not be missing"]
    when 203
      @error = [:email, "has already been taken"]
    when 200
      @error = [:username, "is missing or empty"]
    when 201
      @error = [:password, "is missing or empty"]
    when 205
      @error = [:user, "with specified email not found"]
    else
      raise "Parse error #{code}: #{@error}"
    end
  end
  
  def to_array
    @error[1] = @error[1] + " " + @msg
    @error
  end
  
end
