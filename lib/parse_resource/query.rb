class Query

  def initialize(klass)
    @klass = klass
  end

  def criteria
    @criteria ||= { :conditions => {} }
  end

  def where(args)
    criteria[:conditions].merge!(convert_arg(args))
    self
  end

  def convert_arg(arg)
    return arg.to_pointer if arg.is_a?(ParseResource::Base)
    return ParseResource::Base.to_date_object(arg) if arg.is_a?(Time) || arg.is_a?(Date)
    return arg.update(arg) { |key, inner_arg| convert_arg(inner_arg) } if arg.is_a?(Hash)

    arg
  end

  def limit(limit)
    # If > 1000, set chunking, because large queries over 1000 need it with Parse
    chunk(1000) if limit > 1000

    criteria[:limit] = limit
    self
  end
  
  def include_object(parent)
    criteria[:include] ||= []

    if parent.is_a?(Array)
      parent.each do |item|
        criteria[:include] << item
      end
    else
      criteria[:include] << parent
    end
    self
  end
  
  def order(attr)
    orders = attr.split(" ")
    if orders.count > 1
      criteria[:order] = orders.last.downcase == "desc" ? "-#{orders.first}" : "#{orders.first}"
    else
      criteria[:order] = orders.first
    end
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

  def related_to(obj, key)
    query = { "$relatedTo" => { "object" => obj.to_pointer, "key" => key } }
    criteria[:conditions].merge!(query)
    self
  end

  def execute
    if @klass.has_many_relations
      relations = @klass.has_many_relations.map { |relation| relation.to_s }
      include_object(relations)
    end

    params = {}
    params.merge!({:where => criteria[:conditions].to_json}) if criteria[:conditions]
    params.merge!({:limit => criteria[:limit].to_json}) if criteria[:limit]
    params.merge!({:skip => criteria[:skip].to_json}) if criteria[:skip]
    params.merge!({:count => criteria[:count].to_json}) if criteria[:count]
    params.merge!({:include => criteria[:include].join(',')}) if criteria[:include]
    params.merge!({:order => criteria[:order]}) if criteria[:order]

    return chunk_results(params) if criteria[:chunk]

    resp = @klass.resource.get(:params => params)
    
    if criteria[:count] == 1
      results = JSON.parse(resp)['count']
      return results.to_i
    else
      results = JSON.parse(resp)['results']
      get_relation_objects results.map {|r| @klass.model_name.to_s.constantize.new(r, false)}
    end
  end

  def get_relation_objects(objects)
    if @klass.has_many_relations
      objects.each do |item|
        @klass.has_many_relations.each do |relation|
          item.attributes[relation.to_s] = [] if !item.attributes.has_key?(relation.to_s)
        end
      end
    end

    objects.each do |item|
      item.attributes.each do |key, value|
        value.each do |relation_hash|
          relation_obj = turn_relation_hash_into_object(relation_hash)
          value[value.index(relation_hash)] = relation_obj
        end if value.is_a?(Array) and value[0].is_a?(Hash) and value[0].has_key?("className")
      end
    end
    objects
  end

  def chunk_results(params={})
    criteria[:limit] ||= 100
    
    start_row = criteria[:skip].to_i
    end_row = [criteria[:limit].to_i - start_row - 1, 1].max
    result = []
    
    # Start at start_row, go to end_row, get results in chunks
    (start_row..end_row).each_slice(criteria[:chunk].to_i) do |slice|
      params[:skip] = slice.first
      params[:limit] = slice.length # Either the chunk size or the end of the limited results

      resp = @klass.resource.get(:params => params)
      results = JSON.parse(resp)['results']
      result = result + results.map {|r| @klass.model_name.to_s.constantize.new(r, false)}
      break if results.length < params[:limit] # Got back fewer than we asked for, so exit.
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

  private

  def turn_relation_hash_into_object(hash)
    return nil if hash == nil or hash["className"] == "_User"
    relation_object = hash["className"].to_s.constantize.new if hash["className"] != "_User"
    hash.each do |key, value|
      class_name_in_a_hash = false
      if value.is_a?(Array)
        value.each do |item|
          if item and item.is_a?(Hash)
            class_name_in_a_hash = true if item.has_key?("className")
            break
          end
        end
      end

      if value.is_a?(Array) and class_name_in_a_hash
        value.each do |object_in_array|
          fresh_object = turn_relation_hash_into_object(object_in_array)
          value[value.index(object_in_array)] = fresh_object
        end
        relation_object.attributes[key] = value
      elsif value.is_a?(Hash) and value.has_key?("className")
        relation_object.attributes[key] = turn_relation_hash_into_object(value)
      else
        relation_object.attributes[key] = value if key.to_s != "__type" and key.to_s != "className"
      end
    end

    hash = relation_object
    relation_object
  end

end
