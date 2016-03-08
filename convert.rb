require "ipaddress"
require 'maxminddb'

class Convert
	def initialize(defs)
		@defines=defs
		@resouces=@defines.resourceFiles
		@interests=nil
		@adCompanies=nil
		@db = MaxMindDB.new(@resouces["geoCity"])
		if @defines.options['tablesDB'][@defines.tables["visitsTable"].keys[0]] or @defines.options['tablesDB'][@defines.tables["priceTable"].keys[0]]
			loadInterests
		end
		loadAdCompanies if @defines.options['tablesDB'][@defines.tables["priceTable"].keys[0]]
	end

	def loadAdCompanies
		@defines.puts "Loading list of ad-Companies..."
		@adCompanies=Hash.new
		File.foreach(@defines.resourceFiles["adCompanies"]) {|line| parts=line.split("\t");
			@adCompanies[parts.first.split("/").first]=parts.last}
	end

	def advertiserType(host)
		key=-1
		@adCompanies.keys.each{|company| (key=company;break) if company.downcase.include?(host)}
		return @adCompanies[key].to_s
	end

	def calcPriceValue(val,adCat)
		if Utilities.is_numeric? (val)
  			# If the price is microdollars
			value=val.to_f
   			if(value>100000)
       			value=value/1e6;
			end
    		if(value>100) and not adCat
				Utilities.warning "More than 100 in price "+val
				return nil, false
 			end
			return value,true
		else # this is an effort to find the encrypted values
      		if val.size==11 or val.size==16 or val.size==38 or val.size==39	# 11, 16, 38, 39
				return val, false
			end
      	end
		return nil,false
	end

	def getGeoLocation(ips)
		city=-1
		return city if ips==nil
		if ips.kind_of?(Array)
			return city if ips.size==0
			city=Hash.new(0)
			ips.each{|addr| 
				if IPAddress.valid? addr
					geo=fromIPtoGeo(addr)
					city[geo]+=1
				end	
			}
		else
			if IPAddress.valid? ips
				city=fromIPtoGeo(ips)
			end
		end
		return city
	end

	def analyzePublisher(publisher)
		interest=-1;alexaRank=-1
		return interest,alexaRank if publisher==nil or publisher==-1 or publisher=="encrypted"
		if publisher.include? " "
			temp=publisher
			publisher=temp.split(" ").first
		end
		interests=hostToInterest(publisher)
		alexaRank=-1
		#Utilities.warning "ALEXA RANK IS NOT IMPLEMENTED"
		return interests,alexaRank
	end

	def getTod(time)
		return -1 if time==nil
		if time.to_s.size==13
			time=time.to_f/ 1000.0
		end
		tod=Time.at(time.to_i)#.strftime("%H:%M:%S.%L_%d-%m-%Y")
		if tod.hour>=00 and tod.hour<=03
			return "00:00-03:00"
		elsif tod.hour>=4 and tod.hour<=7
			return "04:00-07:00"
		elsif tod.hour>=8 and tod.hour<=11
			return "08:00-11:00"
		elsif tod.hour>=12 and tod.hour<=15
			return "12:00-15:00"
		elsif tod.hour>=16 and tod.hour<=19
			return "16:00-19:00"
		elsif tod.hour>=20 and tod.hour<=23
			return "20:00-23:00"
		else
			Utilities.warning "Miscalculation of Time"
			return tod.strftime("%H:%M:%S_%d-%m-%Y")
		end
	end

#	def extractInterests(publishers)
#		interests=Array.new
#		return -1 if publishers==nil
#		publishers.each{|pub| interests.push(hostToInterest(pub)); puts pub+" "+hostToInterest(pub).to_s}
#		return interests
#	end

#-----------------------------------------------

private

	def hostToInterest(pubHost)
		return nil if pubHost==nil
		if not pubHost.include? "."
			str=""
			@interests.keys.each {|word| (str=word;break) if word.downcase.include?(pubHost) }
			ints=@interests[str]
		else
			ints=@interests[pubHost]
			if ints==nil
				str=""
				@interests.keys.any? {|word| str=pubHost.downcase.include?(word)}
				ints=@interests[str]
			end
			if ints==nil
				str=""
				@interests.keys.any? {|word| (str=word;break) if word.downcase.include?(pubHost) }
				ints=@interests[str]
			end
		end
		return -1 if ints==nil
		return ints 
	end
	
	def fromIPtoGeo(ip)
		ret = @db.lookup(ip)
		if ret.found? # => true
			if ret.city.name==nil
				return ret.country.name
			else
				return ret.city.name
			end
		else
			return ip
		end
	end

	def loadInterests
		start = Time.now
		filename=@defines.resourceFiles["interestsFile"]
		file = File.read(filename)
	   	json = JSON.parse(file)
    	@interests=json
		@defines.puts "> List of interests has been loaded... in "+(Time.now - start).to_s+" seconds"
	end

	def storeInterests(filename)
		interests=Hash.new
		publisher=""
		cats=Array.new
		File.foreach(filename) {|line|
			if line.size>2
				line=line.gsub("\n","")
				if line.include?("\t")
					parts=line.gsub('"',"").split("\t")
					publisher=parts.first
					interests[publisher]=Hash.new if interests[parts.first]==nil
					topic=parts.last.split(" >").first
				else
					topic=line
					topic=line.split(" >").first if line.include?(">")
				end
				cats.push(topic)
				interests[publisher][topic]=0 if interests[publisher][topic]==nil
				interests[publisher][topic]+=1
			end
		}
		cats=cats.uniq
		interests.each{|pub,topics| cats.each{|cat| interests[pub][cat]=0 if topics[cat]==nil};}
		File.open(@defines.resourceFiles["interestsFile"],"w") do |f|
		  f.write(interests.to_json)
		end
	end
end
