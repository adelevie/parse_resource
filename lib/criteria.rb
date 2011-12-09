class Criteria

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

  #TODO: make this work
  #def skip(skip)
  #  criteria[:skip] = skip
  #  self
  #end

  def count(count)
    criteria[:count] = count
    #self
    all
  end

  def all
    params = {}
    params.merge!({:where => criteria[:conditions].to_json}) if criteria[:conditions]
    params.merge!({:limit => criteria[:limit].to_json}) if criteria[:limit]
    params.merge!({:skip => criteria[:skip].to_json}) if criteria[:skip]
    params.merge!({:count => criteria[:count].to_json}) if criteria[:count]

    resp = @klass.resource.get(:params => params)

    if criteria[:count] == 1
      results = JSON.parse(resp)['count']
      return results.to_i
    else
      results = JSON.parse(resp)['results']
      return results.map {|r| @klass.model_name.constantize.new(r, false)}
    end
  end

  def method_missing(meth, *args, &block)
    if Array.method_defined?(meth)
      all.send(meth, *args, &block)
    else
      super
    end
  end

end
