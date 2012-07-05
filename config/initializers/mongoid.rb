# encoding: utf-8
require 'mongoid'

Mongoid.configure do |config|
		uri = URI.parse(ENV['MONGOHQ_URL'])
		conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
		db = conn.db(uri.path.gsub(/^\//, ''))
end