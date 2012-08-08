# encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'date'
require './models'

configure do
  Mongoid.load!('config/mongoid.yml')
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  alias_method :u, :escape

  def to_c(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end

  def map_reduce(from=nil, to=nil, year=nil, nkid=nil)
    # build horse list
    hrs = {}
    if nkid
      ons = Owner.where('horse.nkid' => nkid)
    elsif year
      ons = Owner.where(year: year)
    else
      ons = Owner.all()
    end
    ons.each{|h|
      hrs[h.horse['nkid']] = {
        'name' => h.horse['name'],
        'sex' => h.horse['sex'],
        'owner' => h.name,
        'year' => h.year,
        'seq' => h.seq
      }
    }
    m = %Q{
      function () {
        var key = {nkid:this.result.nkid};
        var p_1st = 0, p_2nd = 0, p_3rd = 0, p_4th = 0, p_5th = 0;
        var prize = this.result.prize;
        switch(this.result.place){
          case 1:
            p_1st = 1;
            break; //end
          case 2:
            p_2nd = 1;
            break; //end
          case 3:
            p_3rd = 1;
            break; //end
          case 4:
            p_4th = 1;
            break; //end
          case 5:
            p_5th = 1;
            break; //end
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
    # calcurate results
    res = []
    col = Race
    if year or nkid
      col = col.in('result.nkid' => hrs.keys)
    end
    if from
      col = col.where(:race_date.gte => from.to_time).where(:race_date.lte => to.to_time)
    end
    col.map_reduce(m, r).out(inline: true).each{|r|
      res.push({
        'nkid' => r['_id']['nkid'].to_i,
        'name' => hrs[r['_id']['nkid'].to_i]['name'],
        'sex' => hrs[r['_id']['nkid'].to_i]['sex'],
        'owner' => hrs[r['_id']['nkid'].to_i]['owner'],
        'year' => hrs[r['_id']['nkid'].to_i]['year'].to_i,
        'seq' => hrs[r['_id']['nkid'].to_i]['seq'].to_i,
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
  
  def recent_race(n=nil)
  	res = []
  	if n
	  r = Race.desc(:race_date).limit(n)
	else
	  r = Race.desc(:race_date)
	end
    r.each{|r|
      horse = Owner.find_by_nkid(r.result['nkid'].to_i)
      res.push({
      	'nkid' => r.result['nkid'],
      	'date' => r.race_date,
      	'place' => r.place,
      	'race_num' => r.race_num,
      	'race_name' => r.name,
      	'length' => r.length,
      	'horse' => horse['name'],
      	'jocky' => r.result['jocky'],
      	'owner' => horse['owner'],
      	'r_place' => r.result['place'],
      	'pop' => r.result['popularity'],
      	'prize' => r.result['prize']
      })
    }
    return res
  end
  
  def aggregates_by_owner(results)
    res = results.group_by{|i|
      i['owner']
    }.reduce({}){|r, kv|
      res = {
        'prize' => 0.0,
        'races' => 0,
        'p1' => 0,
        'p2' => 0,
        'p3' => 0,
        'p4' => 0,
        'p5' => 0
      }
      kv[1].each{|race|
        res['prize'] += race['prize']
        res['races'] += race['races']
        res['p1'] += race['p1']
        res['p2'] += race['p2']
        res['p3'] += race['p3']
        res['p4'] += race['p4']
        res['p5'] += race['p5']
      }
      r.update({kv[0] => res})
    }
    return res
  end
  
  def results_of_owner(from=nil, to=nil, year=nil)
    # 馬別の成績を計算する
  	@mr_results = map_reduce(from, to, year)
    @res_owner = aggregates_by_owner(@mr_results)

    # 個人順位を計算する
    @res_owner_recalc = {}
    if year
      key = year
    else
      key = "all"
    end
  	@res_owner_recalc.update({key => {}})
  	o = Owner.find_owners_by_year(year)
  	o.each{|name|
  	  @res_owner_recalc[key].update({name => 0})
  	}
    @res_owner.each_key{|name|
      p = @res_owner[name]['prize'].to_i
      @res_owner_recalc[key].each_key{|res_name|
        prize = @res_owner_recalc[key][res_name].to_i
        if res_name == name
      	  @res_owner_recalc[key].update({res_name => prize + p * (@res_owner_recalc[key].length - 1)})
        else
     	  @res_owner_recalc[key].update({res_name => prize - p})
        end
      }
    }
    return {key => @res_owner_recalc[key].sort{|a,b|b[1]<=>a[1]}}
  end
  
  # 過去からの順位の上下を追加して返す
  def ranking(cur,prv)
    cur.each_key{|k1|
      cur[k1].each_index{|i|
        prv[k1].each_index{|j|
          if cur[k1][i][0] == prv[k1][j][0]
            if i==j
              cur[k1][i].push(0)
            elsif i<j
              cur[k1][i].push(1)
            else
              cur[k1][i].push(-1)
            end
          end
        }
      }
    }
    return cur
  end
end

# Routes
get '/' do
  span=[]
  Duration.where(dtype: 'ranking').desc(:end).limit(2).each{|d|
    span.push([d.start, d.end])
  }

  @recent = recent_race(15)
  @dashboard = true
  prv = results_of_owner(span[1][0],span[1][1])
  cur = results_of_owner(span[0][0],span[0][1])
  
  ranking = ranking(cur,prv)
  @ranking_all = ranking['all']
  @span = [span[0][0],span[0][1]]
  erb :index
end

get '/horse/:nkid' do
  @horses = true
  @horse = Owner.find_by_nkid(params[:nkid].to_i)
  @races = Race.find_by_nkid(params[:nkid].to_i)
  @results = map_reduce(nil, nil, nil, params[:nkid].to_i)
  erb :horse
end

get '/horse' do
  @horses = true
  d_from = nil
  d_to = nil
  year = nil

  begin
    if params['from'] and params['to']
      d_from = Date.parse(params['from'])
      d_to = Date.parse(params['to'])
    else
      d_from = nil
      d_to = nil
    end
  rescue ArgumentError
    d_from = nil
    d_to = nil
  end

  begin
    if params['year']
      year = params['year'].to_i
    end
  rescue ArgumentError
    year = nil
  end  
  @mr_results = map_reduce(d_from, d_to, year)
  erb :mapreduce
end

get '/race' do
  @race = true
  @recent = Race.recent_races()
  erb :races
end

get '/duration' do
  @dur = Duration.all()
  erb :dur_index
end

get '/duration/new' do
  erb :dur_new
end

post '/duration/new' do
  redirect '/'
end

get '/duration/:id' do |id|
  erb :dur_show
end

get '/duration/edit/:id' do |id|
  erb :dur_edit
end

put '/duration/update/:id' do |id|
  erb :dur_show
end

delete '/duration/delete/:id' do
  erb :dur_show
end
