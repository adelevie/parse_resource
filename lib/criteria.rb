class Criteria

  def initialize(klass)
    @klass = klass
  end

  def criteria
    @criteria ||= { :conditions => {} }
  end

  def where(args)
    critera[:conditions].merge!(args)
    self
  end

  def limit(limit)
    criteria[:limit] = limit
    self
  end

  def each(&block)
    resp = resource.get(:params => {:where => criteria[:conditions].to_json}
    results = JSON.parse(resp)['results']
    results.map {|r| model_name.constantize.new(r, false)}.each(&block)
  end

  def first
    resp = resource.get(:params => {:where => criteria[:conditions].to_json}
    results = JSON.parse(resp)['results']
    results.map {|r| model_name.constantize.new(r, false)}.first
  end


end
