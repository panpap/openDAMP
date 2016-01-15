require 'fastimage'
require 'rubygems'
require 'json'
require 'sqlite3'

class Filters

    def getLatency
        return @latency
    end

	def initialize(defs)
		@defines=defs
		@latency=Array.new
		begin
			@db = SQLite3::Database.open "results.db"
			@db.execute "CREATE TABLE IF NOT EXISTS BeaconURLs(url TEXT PRIMARY KEY, 
				singlePixel BOOLEAN)"
		rescue SQLite3::Exception => e 
			puts "Exception occurred"
			puts e
		end
	end

	def close
		@db.close if db
	end

    def loadExternalFilter
       	file = File.read(@defines.filterFile)
       	json = JSON.parse(file)
        cats=json['categories']
       	filter=Hash.new
        for cat in cats.keys do
                cats[cat].each{ |subCats| subCats.each {|key,values|
                        values.each { |val| val.each{ |doms| (doms.each{|k| filter[k]=cat+"#"+key}) if not doms.is_a?(String)}}}}
        end
#       filter.each {|key,value| puts key+" "+value.to_s}
        return filter
    end

	def is_inInria_PriceTagList? (domain,keyVal)
		temp=@defines.inria[domain]
		if temp!=nil and temp.downcase.eql? keyVal[0]
			return true
		end
		return false
	end

    def is_Beacon_param?(params)
        return (@defines.beacon_key.any? {|word| params[0].downcase.include?(word)})
    end

    def is_Beacon?(url)
		if is_1pixel_image?(url)
			return true
        elsif (url.downcase.include? ".htm" or url.downcase.include? ".xml")
            return false
        elsif(@defines.beacon_key.any? { |word| url.include?(word)})
            return true
        else
        	return false
        end
    end

	def is_Browser?(row,type)
		ua=row['ua'].downcase
		if (type=="Macintosh" or type=="Windows" or type=="Linux" or type=="BSD") # IS DESKTOP?
	       return true
		elsif (@defines.browsers.any? { |word| ua.include?(word)})     # IS BROWSER?
	       return true
		else                                                    # IS APP... DO NOTHING
	       return false
		end
	end

    def is_MobileType?(row)
        ua=row["ua"].downcase
        # Crossed-checked with https://fingerbank.inverse.ca
        if (ua.include? "android" or ua.include? "dalvik" or ua.include? "play.google" or ua.include? "agoo-sdk" or ua.include? "okhttp")
            return true, "Android"
        elsif ua.include? "iphone"
            return true, "iPhone"
        elsif ua.include? "ipad"
            return true,"iPad"
        elsif ua.include? "windows"
            if ua.include? "arm" or ua.include? "nokia"
                return true, "Windows Mobile"
            else
                return false,"Windows"
            end
        elsif ua.include? "macintosh"
            return false,"Macintosh"
        elsif (ua.include? "linux" or ua.include? "ubuntu")
            return false,"Linux"
        elsif (ua.include? "darwin" or ua.include? "ios" or ua.include? "CFNetwork" or ua.include? "apple.mobile" or ua.include? "com.apple.Map")
            return true,"Apple Mobile"
        elsif (ua.include? "freebsd" or ua.include? "openbsd")
            return false,"BSD"
        else
        	return false,"other"
        end
    end

    def is_Impression?(url)
        if (url.include? "impl") #junk
            return false
        end
        return (@defines.imps.any? { |word| url.downcase.include?(word)})
    end


	def is_GarbageOrEmpty?(str) #filter out version, density parameters
        return (str[1]==nil or str[0].eql? "v" or str[0].downcase.include? "ver" \
                    or str[0].eql? "density" or str[0].eql? "u_sd")
    end

    def has_PriceKeyword?(param)            # Check if there is a price-related keyword and return the price
       if param[0].eql? "latency"
            @latency.push(param[1].to_f)
            fa=File.new('./latency.out','a')
            fa.puts param[1]
            fa.close
       end
       return (@defines.keywords.any? { |word| param[0].downcase.eql?(word)})# and is_numeric?(param[1]))
    end

	def is_Ad?(url,host,filter)
        str=url
        urlParts=url.split("/")
        parts=host.split(".")
# FIND TLD AND DOMAIN
		domain,tld=Utilities.tokenizeHost(host)

# FILTER USING DISCONNECT
        if result=filter[host]                                  # APPLY FILTER
            return result.split("#")[0]
        elsif (host.count('.')>1 && result=filter[domain+"."+tld])      # APPLY FILTER NOT IN SUBDOMAIN
            return result.split("#")[0]
        else           
 # FILTER USING KEYWORDS
            if (tld=="ad") # TLD check REMOVE ".ad" TLDs
                parts.delete_at(parts.size-1)
                s="";t="/";
                parts.each{ |p| s+=p+"." "" }
                urlParts[1,urlParts.size].each{ |p| t+=p+"/" ""}
                url=s+t
            end
            if (@defines.subStrings.any? { |word| url.include?(word)} or @defines.rtbCompanies.any? { |word| url.downcase.include?(word)})
                return "Advertising"
            end
            return nil
        end
    end

    def is_Ad_param?(params)
        if (params[0].downcase.eql? "type" and params[1].include? "ad")
            return true
        else
            return (@defines.adInParam.any? {|word| params[0].downcase.include?(word)})
        end
    end

#-----------------------------------------------------------------------------------

private

    def is_1pixel_image?(url)
        if [".jpeg", ".gif", ".png" ,"bmp"].any? {|word| url.downcase.include?(word)} #IS IMAGE?
			if # I've already seen that url 
				row = @db.get_first_row "SELECT singlePixel FROM BeaconURLs WHERE url="+url       
    			puts row
				return str == 'TRUE'
			else	# no... wget it
				begin
					pixels=FastImage.size("http://"+url)
				    if pixels==[1,1]         # 1x1 pixel
						@db.execute "INSERT INTO BeaconURLs VALUES("+url+",TRUE)"
				        return true
					else
						@db.execute "INSERT INTO BeaconURLs VALUES("+url+",FALSE)"
				        return false
				   	end
					rescue
						puts "Connection Error"
					end	
				end
			end
        end
        return false
    end
end
