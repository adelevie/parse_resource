require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
begin
  require 'turn/autorun'; 
  # Turn.config.trace = 8
  Turn.config.format = :outline
rescue LoadError
end
require 'test/unit'
require 'vcr'
require 'webmock/test_unit'

if ENV["PARSE_RESOURCE_APPLICATION_ID"].nil? && ENV["PARSE_RESOURCE_MASTER_KEY"].nil?
  path = "parse_resource.yml"
  settings = YAML.load(ERB.new(File.new(path).read).result)['test']
  ENV["PARSE_RESOURCE_APPLICATION_ID"] = settings['app_id']
  ENV["PARSE_RESOURCE_MASTER_KEY"] = settings['master_key']
end

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
  c.allow_http_connections_when_no_cassette = true
end

#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib/' )
require 'parse_resource'

class Test::Unit::TestCase
end

def item_with_value_exists_in_array?(array, method_to_call_on_each_item, object_to_find)
  # ignore dates
  object_to_find.delete("updatedAt")
  object_to_find.delete("createdAt")
  object_to_find.each_pair do |k,v|
    object_to_find.delete(k) if v.is_a?(Array) && v.empty?
  end
  array.each do |item|
    temp_item = item.clone
    temp_item.attributes.delete("updatedAt")
    temp_item.attributes.delete("createdAt")
    temp_item.attributes.each_pair { |k,v| temp_item.attributes.delete(k) if v.is_a?(Array) && v.empty?}
    return true if temp_item.send(method_to_call_on_each_item) == object_to_find
  end
  false
end