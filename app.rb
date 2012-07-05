# encoding: utf-8
require 'rubygems'
require 'sinatra'
require './models'

configure do
	load File.expand_path('../config/initializers/mongoid.rb',__FILE__)
end

helpers do
	def horses
		items = Array.new
		Owner.find_horses_by_owner("エトゥ").asc(:year).each{|h|
			items.push(h.horse['name'])
		}
		return items
	end
end

get '/' do
	@items = horses()
	erb :index
end

get '/horse/:nkid' do
	@horse = Owner.find_by_nkid(params[:nkid].to_i)
	@races = Race.find_by_nkid(params[:nkid].to_i)
	erb :horse	
end