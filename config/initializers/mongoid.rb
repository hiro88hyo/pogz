# encoding: utf-8
require 'mongoid'

Mongoid.configure do |config|
  if ENV['MONGOHQ_URL']
    uri  = URI.parse(ENV['MONGOHQ_URL'])
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    config.master = conn.db(uri.path.gsub(/^\//, ''))
  else
    env = Sinatra::Application.environment rescue nil
#    name = env == :test ? 'test' : 'development'
    host = 'localhost'
    config.master = Mongo::Connection.new.db(name)
  end
end