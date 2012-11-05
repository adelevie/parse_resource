class Query

  def initialize(klass)
    @klass = klass
  end

  def criteria
    @criteria ||= { :conditions => {} }
  end

  def where(args)
    criteria[:conditions].merge!(args)
    self
  end

  def limit(limit)
    criteria[:limit] = limit
    self
  end
  
  def include_object(parent)
    criteria[:include] = parent
    self
  end
  
  # deprecating until it works
  def order(attr)
    orders = attr.split(" ")
    if orders.count > 1
      criteria[:order] = orders[1] == "desc" ? "-#{orders[0]}" : "#{orders[0]}"
    end
    self
  end

  def skip(skip)
   criteria[:skip] = skip
   self
  end

  def count(count=1)
    criteria[:count] = count
    #self
    all
  end

  def near(klass, geo_point, options)
    if geo_point.is_a? Array
      geo_point = ParseGeoPoint.new :latitude => geo_point[0], :longitude => geo_point[1]
    end

    query = { "$nearSphere" => geo_point.to_pointer }
    if options[:maxDistanceInMiles]
      query["$maxDistanceInMiles"] = options[:maxDistanceInMiles]
    elsif options[:maxDistanceInRadians]
      query["$maxDistanceInRadians"] = options[:maxDistanceInRadians]
    elsif options[:maxDistanceInKilometers]
      query["$maxDistanceInKilometers"] = options[:maxDistanceInKilometers]
    end

    criteria[:conditions].merge!({ klass => query })
    self
  end

  def within_box(klass, geo_point_south, geo_point_north)
    if geo_point_south.is_a? Array
      geo_point_south = ParseGeoPoint.new :latitude => geo_point_south[0], :longitude => geo_point_south[1]
    end

    if geo_point_north.is_a? Array
      geo_point_north = ParseGeoPoint.new :latitude => geo_point_north[0], :longitude => geo_point_north[1]
    end

    query = { "$within" => { "$box" => [geo_point_south.to_pointer, geo_point_north.to_pointer]}}
    criteria[:conditions].merge!({ klass => query })
    self
  end

  def execute
    params = {}
    params.merge!({:where => criteria[:conditions].to_json}) if criteria[:conditions]
    params.merge!({:limit => criteria[:limit].to_json}) if criteria[:limit]
    params.merge!({:skip => criteria[:skip].to_json}) if criteria[:skip]
    params.merge!({:count => criteria[:count].to_json}) if criteria[:count]
    params.merge!({:include => criteria[:include]}) if criteria[:include]
    params.merge!({:order => criteria[:order]}) if criteria[:order]

    resp = @klass.resource.get(:params => params)
    
    if criteria[:count] == 1
      results = JSON.parse(resp)['count']
      return results.to_i
    else
      results = JSON.parse(resp)['results']
      return results.map {|r| @klass.model_name.constantize.new(r, false)}
    end
  end

  def all
    execute
  end

  def method_missing(meth, *args, &block)
    if Array.method_defined?(meth)
      all.send(meth, *args, &block)
    else
      super
    end
  end

  def respond_to?(meth)
    if Array.method_defined?(meth)
      true
    else
      super
    end
  end

end
