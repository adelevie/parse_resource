class ParseRole < ParseResource::Base
  fields :name, :users, :roles

  def name
    val = get_attribute("name")
  end

  def users
    val = User.related_to(self, :users)
  end

  def self.add_user(user_id)
    base_uri   = "https://api.parse.com/1/roles"
    app_id     = settings['app_id']
    master_key = settings['master_key']
    resource = RestClient::Resource.new(base_uri, app_id, master_key)
    
    begin
      resp = resource.put(:params => {:id => self.objectId, :users => {"__op" => "AddRelation", "objects" => [{ "__type" => "Pointer", "className" => "_User", "objectId" => user.objectId}]}})
      resp
    rescue
      debug 
      false
    end
    
  end

end
