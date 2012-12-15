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
    # If > 1000, set chunking, because large queries over 1000 need it with Parse
    chunk(1000) if limit > 1000

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
    all
  end

  # Divides the query into multiple chunks if you're running into RestClient::BadRequest errors.
  def chunk(count=100)
    criteria[:chunk] = count
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

    return chunk_results if criteria[:chunk]

    resp = @klass.resource.get(:params => params)
    
    if criteria[:count] == 1
      results = JSON.parse(resp)['count']
      return results.to_i
    else
      results = JSON.parse(resp)['results']
      return results.map {|r| @klass.model_name.constantize.new(r, false)}
    end
  end

  def chunk_results
    start_row = criteria[:skip].to_i
    end_row = criteria[:limit] - start_row
    result = []

    # Start at start_row, go to end_row, get results in chunks
    [start_row..end_row].each_slice(criteria[:chunk].to_i) do |slice|
      params[:skip] = slice.first
      params[:limit] = criteria[:chunk]
      resp = @klass.resource.get(:params => params)
      results = JSON.parse(resp)['results']
      result = result + results.map {|r| @klass.model_name.constantize.new(r, false)}
    end
    result
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
