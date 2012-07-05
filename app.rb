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
	
	def map_reduce
		m = %Q{
			function () {
    			var key = {
    				nkid:this.result.nkid
    			};
    			var p_1st = 0, p_2nd = 0, p_3rd = 0, p_4th = 0, p_5th = 0;
    			var prize = this.result.prize;
    			switch(this.result.place){
    				case 1:
    					p_1st = 1;
    					break;
    				case 2:
    					p_2nd = 1;
    					break;
    				case 3:
    					p_3rd = 1;
    					break;
    				case 4:
    					p_4th = 1;
    					break;
    				case 5:
    					p_5th = 1;
    					break;
		    	}
    			emit(key, {prize: prize, count: 1, p_1st: p_1st, p_2nd: p_2nd, p_3rd: p_3rd, p_4th: p_4th, p_5th: p_5th});
			}
		}

		r = %Q{
			function (key, values) {
    			var pr = 0.0, co = 0;
    			var p1st = 0, p2nd = 0, p3rd = 0, p4th = 0, p5th = 0;
    			values.forEach(function (value) {
    				pr += value.prize;
    				co += value.count;
    				p1st += value.p_1st;
    				p2nd += value.p_2nd;
    				p3rd += value.p_3rd;
    				p4th += value.p_4th;
    				p5th += value.p_5th;
		    	});
    		return {prize:pr, count:co, p_1st:p1st, p_2nd:p2nd, p_3rd:p3rd, p_4th:p4th, p_5th: p5th};
			}
		}
		res = []
		Race.collection.map_reduce(m,r, {:out => {:inline => true}, :raw => true})['results'].each{|r|
			res.push({
				'nkid' => r['_id']['nkid'].to_i,
				'races' => r['value']['count'].to_i,
				'prize' => r['value']['prize'].to_f,
				'p1' => r['value']['p_1st'].to_i,
				'p2' => r['value']['p_2nd'].to_i,
				'p3' => r['value']['p_3rd'].to_i,
				'p4' => r['value']['p_4th'].to_i,
				'p5' => r['value']['p_5th'].to_i				
			})
		}
		return res.sort{|a, b| b['prize']<=>a['prize']}
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

get '/mapreduce' do
	@mr_results = map_reduce()
	res = ''
	@mr_results.each{|r|
		res << "nkid:<a href='/horse/#{r['nkid']}'>#{r['nkid']}</a> races:#{r['races']} prize:#{r['prize']} 1st:#{r['p1']} 2nd:#{r['p2']} 3rd:#{r['p3']} 4th:#{r['p4']} 5th:#{r['p5']}<br/>"
	}
	res
end