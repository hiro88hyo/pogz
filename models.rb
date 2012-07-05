# encoding: utf-8
require 'rubygems'
require 'mongoid'

class Owner
	include Mongoid::Document
	include Mongoid::Timestamps
	
	field :name, type: String
	field :year, type: Integer
	field :seq, type: Integer
	embeds_one :horses
	
	def self.find_horses_by_owner(name)
		self.where(name: name)
	end
	
	def self.find_by_horse_name(name)
		self.where("horse.name" => name).first()
	end

	def self.build_responce(o)
		{"name" => o.horse['name'],
		 "owner" => o.name,
		 "year" => o.year,
		 "seq" => o.seq,
		 "sex" => o.horse['sex'],
		 "trainer" => o.horse['trainer'],
		 "father" => o.horse['father'],
		 "mother" => o.horse['mother'],
		 "bms" => o.horse['bms'],
		 "real_owner" => o.horse['real_owner'],
		 "farm" => o.horse['farm']
		}
	end
	
	def self.find_by_nkid(id)
		return build_responce(Owner.where("horse.nkid" => id).first)
	end

end

class Horse
	include Mongoid::Document
	
	field :nkid, type: Integer
	field :name, type: String
	field :sex, type: String
	field :area, type: String
	field :trainer, type: String
	field :father, type: String
	field :mother, type: String
	field :bms, type: String
	field :real_owner, type: String
	field :farm, type: String
	embedded_in :owners
end

class Race
 	include Mongoid::Document
 	include Mongoid::Timestamps
 	
 	field :race_id, type: String
 	field :race_date, type: Date
 	field :place, type: String
 	field :race_num, type: Integer
 	field :name, type: String
 	field :length, type: String
 	field :condition, type: String
 	field :horses_num, type: Integer
 	embeds_one :result
 	
 	def self.find_race_by_horse(name)
		owner = Owner.where("horse.name" => name).first
		if owner
			return self.where("result.nkid" => owner.horse["nkid"]).desc(:race_date)
		end
	end
	
	def self.build_responce(r)
		{"rid" => r.race_id,
		 "race_date" => r.race_date,
		 "place" => r.place,
		 "race_num" => r.race_num,
		 "name" => r.name,
		 "length" => r.length,
		 "condition" => r.condition,
		 "horses_num" => r.horses_num,
		 "r_nkid" =>  r.result['nkid'],
		 "r_post" =>  r.result['post'],
		 "r_position" =>  r.result['position'],
		 "r_odds" =>  r.result['odds'],
		 "r_popularity" =>  r.result['popularity'],
		 "r_jocky" =>  r.result['jocky'],
		 "r_place" =>  r.result['place'],
		 "r_prize" =>  r.result['prize']	 
		}
	end
	
	def self.find_by_nkid(id)
		res = []
		r = self.where("result.nkid" => id).asc(:race_date)
		if r
			r.each{|race|
				res.push(build_responce(race))
			}
		end
		return res
	end
end

class Result
	include Mongoid::Document
	
	field :nkid, type: Integer
	field :post, type: Integer
	field :position, type: Integer
	field :odds, type: Float
	field :popularity, type: Integer
	field :jocky, type: String
	field :place, type: Integer
	field :prize, type: Float, default: 0.0
	embedded_in :race
end