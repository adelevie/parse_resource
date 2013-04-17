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
