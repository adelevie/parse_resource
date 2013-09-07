class ParseRole < ParseResource::Base
  fields :name, :users, :roles

  def users
    User.related_to(self, :users)
  end

  def access_control
    get_attribute("ACL")
  end

  def self.create(attributes)
    base_uri   = "https://api.parse.com/1/roles"
    app_id     = settings['app_id']
    master_key = settings['master_key']
    resource = RestClient::Resource.new(base_uri, app_id, master_key)
    data = {"name" => attributes[:name],
            "ACL" => {
              "*" => {
                "read" => attributes[:ACL][:read] ? attributes[:ACL][:read] : false,
                "write" => attributes[:ACL][:write] ? attributes[:ACL][:write] : false}}}
    json_data = data.to_json
    begin
      resp = resource.post json_data, :content_type => "application/json"
      role = Role.find(JSON.parse(resp)["objectId"])
    rescue
      false
    end    
  end

  def add_user(user)
    # Expects user parameter to be a ParseUser object
    base_uri   = "https://api.parse.com/1/roles/#{self.objectId}"
    app_id     = self.class.settings['app_id']
    master_key = self.class.settings['master_key']
    resource = RestClient::Resource.new(base_uri, app_id, master_key)
    data = {"users" => {"__op" => "AddRelation", 
                        "objects" => [{"__type" => "Pointer", 
                                       "className" => "_User", 
                                       "objectId" => user.objectId}] } }
    json_data = data.to_json
    begin
      resp = resource.put json_data, :content_type => "application/json"
    rescue
      false
    end
  end

  def remove_user(user)
    # Expects user parameter to be a ParseUser object
    
    base_uri   = "https://api.parse.com/1/roles/#{self.objectId}"
    app_id     = self.class.settings['app_id']
    master_key = self.class.settings['master_key']
    resource = RestClient::Resource.new(base_uri, app_id, master_key)
    data = {"users" => {"__op" => "RemoveRelation", 
                        "objects" => [{"__type" => "Pointer", 
                                       "className" => "_User", 
                                       "objectId" => user.objectId}] } }
    json_data = data.to_json
    begin
      resp = resource.put json_data, :content_type => "application/json"
    rescue
      false
    end
  end

end
