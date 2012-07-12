# encoding: utf-8
require './models'

def print_race(name)
	o = Owner.find_by_horse_name(name)	
	nkid = o.horse['nkid']
	r = Race.find_race_by_horse(name)
	j = [0,0,0,0,0]
	p = 0.0
	games = 0
	if r
		r.each{|race|
#			race.result.each{|res|
#				if res.nkid==nkid
					puts "#{race.race_date}¥t#{race.result.place}¥t#{race.result.nkid}"
					p += race.result.prize
					games += 1
					case race.result.place
					when 1
						j[0] += 1
					when 2
						j[1] += 1
					when 3
						j[2] += 1
					when 4
						j[3] += 1
					when 5
						j[4] += 1
					end
#				end
#			}
		}
	end
	puts "#{games}戦, 1着 #{j[0]}, 2着 #{j[1]}, 3着 #{j[2]}, 4着 #{j[3]}, 5着 #{j[4]}, 賞金 #{p}"
	puts ""
end

def print_horse_info(name)
	o = Owner.find_by_horse_name(name)
	if o
		h = o.horse
		puts "馬名　：#{h['name']}"
		puts "所有者：#{o.name}"
		puts "年　　：#{o.year}"
		puts "指名順：#{o.seq}"
		puts "性別　：#{h['sex']}"
		puts "調教師：#{h['trainer']}"
		puts "父　　：#{h['father']}"
		puts "母　　：#{h['mother']}"
		puts "母父　：#{h['bms']}"
		puts "馬主　：#{h['real_owner']}"
		puts "生産　：#{h['farm']}"
		puts ""
		print_race(name)
	end
end

def ranking(year)
end

Mongoid.configure{|conf|
	conf.master = Mongo::Connection.new('localhost', 27017).db('learning')
}

#p Owner.find_horses_by_owner("エトゥ")
#Race.find_race_by_horse("ストローハット").each{|r|
#	p r.result
#}

#Owner.find_horses_by_owner("エトゥ").each{|a|
#	print_horse_info(a.horse['name'])
#}

print_horse_info("ストローハット")