require 'maxminddb'

class Convert
	def initialize(defs)
		@resouces=defs.resourceFiles
	end

	def calcPriceValue(val)
		if Utilities.is_float? (val)
  			# If the price is microdollars
			value=val.to_f
   			if(value>100000)
       			value=value/1e6;
			end
    		if(value>100)
				Utilities.warning "More than 100 in price "+val
 			end
			return value,true
		else # this is an effort to find the encrypted values
      		if val.size==11 or val.size==16 or val.size==38 or val.size==39	# 11, 16, 38, 39
				return val,false
			end
      	end
		return nil,false
	end

	def getGeoLocation(ips)
		city=-1
		return city if ips==nil
		if ips.kind_of?(Array)
			city=Hash.new(0)
			ips.each{|addr| 
				geo=fromIPtoGeo(addr)
				city[geo]+=1	
			}
		else
			city=fromIPtoGeo(ips)
		end
		return city
	end

	def analyzePublisher(publisher)
		interest=-1;alexaRank=-1
		return interest,alexaRank if publisher==nil
		interest=extractInterests(publisher)
		Utilities.warning "NOT IMPLEMENTED"
		return interest,alexaRank
	end

	def getTod(time)
		return -1 if time==nil
		if time.to_s.size==13
			time=time/ 1000.0
		end
		tod=Time.at(time)#.strftime("%H:%M:%S.%L_%d-%m-%Y")
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

	def extractInterests(publishers)
		interests=Array.new
		return -1 if publishers==nil
		publishers.each{|host| interest,alexaRank=analyzePublisher(host); interests.push(interest)}
		return interests
	end

#-----------------------------------------------

private

	def fromIPtoGeo(ip)
		db = MaxMindDB.new(@resouces["geoCity"])
		ret = db.lookup(ip)
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
end
