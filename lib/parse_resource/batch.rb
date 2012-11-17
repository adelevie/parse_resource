# module ParseResource
#   class Batch
#     def self.resource
#       if @@settings.nil?
#         path = "config/parse_resource.yml"
#         environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
#         @@settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
#       end

#       if model_name == "User" #https://parse.com/docs/rest#users-signup
#         base_uri = "https://api.parse.com/1/users"
#       else
#         base_uri = "https://api.parse.com/1/classes/#{model_name}"
#       end

#       #refactor to settings['app_id'] etc
#       app_id     = @@settings['app_id']
#       master_key = @@settings['master_key']
#       RestClient::Resource.new(base_uri, app_id, master_key)
#     end
#   end
# end