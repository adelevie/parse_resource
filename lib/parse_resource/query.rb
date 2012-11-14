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
  
  def order(attribute)
    attribute = attribute.to_sym if attribute.is_a?(String)
    criteria[:order] = attribute
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

  def first
    limit(1)
    execute.first
  end

  def all
    execute
  end

  def method_missing(meth, *args, &block)
    method_name = method_name.to_s
    if method_name.start_with?("find_by_")
      attrib   = method_name.gsub(/^find_by_/,"")
      finder_name = "find_all_by_#{attrib}"

      define_singleton_method(finder_name) do |target_value|
        where({attrib.to_sym => target_value}).first
      end

      send(finder_name, args[0])

    elsif method_name.start_with?("find_all_by_")
      attrib   = method_name.gsub(/^find_all_by_/,"")
      finder_name = "find_all_by_#{attrib}"

      define_singleton_method(finder_name) do |target_value|
        where({attrib.to_sym => target_value}).all
      end

      send(finder_name, args[0])
    end

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
