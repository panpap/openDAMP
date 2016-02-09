require 'fastimage'
require 'rubygems'
require 'json'
load 'keywordsLists.rb'

class Filters

	def initialize(defs)
		@defines=defs
		@publishers=Hash.new(nil)
		@latency=Array.new
		@lists=KeywordsLists.new(@defines.files["filterFile"])
		@db = Database.new(@defines,@defines.beaconDB)
		@lastPub=Hash.new(nil)
		@db.create(@defines.beaconDBTable,'url VARCHAR PRIMARY KEY, singlePixel BOOLEAN')
	end

	def close
		puts "CLOSING BEACON DB..."
		@db.close if db
	end

	def translateHTMLContent(str)
Utilities.error "pwwwwwww "+line if str==nil
		t1=str.split(";")[0]
		type=t1.split(":")[0].gsub(" ","").downcase
		return @lists.types[type]
	end

	def is_inInria_PriceTagList? (domain,keyVal)
		temp=@lists.inria[domain]
		if temp!=nil and temp.downcase.eql? keyVal[0]
			return true
		end
		return false
	end

    def is_Beacon_param?(params)
        return (@lists.beacon_key.any? {|word| params[0].downcase.include?(word)})
    end

    def is_Beacon?(url,type,force)
		if (@lists.beacon_key.any? { |word| url.include?(word)})
			return true
		elsif ([".jpeg", ".gif", ".png" ,".bmp"].any? {|word| url.downcase.include?(word)}) or type=="image" or force
		    return is_1pixel_image?(url)
		else
			return false
		end
    end

	def is_Browser?(row)
		browser="unknown"			# IS APP... DO NOTHING
		ua=row['ua'].downcase
		@lists.browsers.any? { |word| browser=word if ua.include?(word) }     # IS BROWSER? 
	    return browser
	end

    def is_MobileType?(row)
        ua=row["ua"].downcase
        # Crossed-checked with https://fingerbank.inverse.ca
        if (ua.include? "android" or ua.include? "dalvik" or ua.include? "play.google" or ua.include? "agoo-sdk" or ua.include? "okhttp")
            return 1, "Android"
        elsif ua.include? "iphone"
            return 1, "iPhone"
        elsif ua.include? "ipad"
            return 1,"iPad"
        elsif ua.include? "windows"
            if ua.include? "arm" or ua.include? "nokia"
                return 1, "Windows_Mobile"
            else
          		return 0,"Windows"
            end
        elsif ua.include? "macintosh"
            return 0,"Macintosh"
        elsif (ua.include? "linux" or ua.include? "ubuntu")
            return 0,"Linux"
        elsif (ua.include? "darwin" or ua.include? "ios" or ua.include? "CFNetwork" or ua.include? "apple.mobile" or ua.include? "com.apple.Map")
            return 1,"Apple_Mobile"
        elsif (ua.include? "freebsd" or ua.include? "openbsd")
            return 0,"BSD"
        else
        	return 0,"other"
        end
    end

    def is_Impression?(url)
        if (url.include? "impl") #junk
            return false
        end
        return (@lists.imps.any? { |word| url.downcase.include?(word)})
    end


	def is_GarbageOrEmpty?(str) #filter out version, density parameters
        return (str[1]==nil or str[0].eql? "v" or str[0].downcase.include? "ver" \
                    or str[0].eql? "density" or str[0].eql? "u_sd")
    end

    def has_PriceKeyword?(param)            # Check if there is a price-related keyword and return the price
       return (@lists.keywords.any? { |word| param[0].downcase.eql?(word)})# and is_numeric?(param[1]))
    end

	def is_Ad?(urlAll,host,user)
		url=urlAll[0]
		rootUrl=url.gsub("/","")
		if rootUrl.count('.')==2
			tmp=rootUrl.split(".")
			rootUrl=tmp[tmp.size-2]+"."+tmp[tmp.size-1]
		end
		if urlAll[1]==nil and rootUrl==host
			@publishers[host]=user
			@lastPub[user]=host
			return "Other" #Publisher
		end
		value=@publishers[host]
		if value==user
			return "Other"
		end
        str=url
        urlParts=url.split("/")
        parts=host.split(".")
		# FIND TLD AND DOMAIN
		domain,tld=Utilities.tokenizeHost(host)
		# FILTER USING DISCONNECT
        if cat=findCategory(host,domain,tld,@lastPub[user])
			return cat
        else           
			 # FILTER USING KEYWORDS
            if (tld=="ad") # TLD check REMOVE ".ad" TLDs
                parts.delete_at(parts.size-1)
                s="";t="/";
                parts.each{ |p| s+=p+"." "" }
                urlParts[1,urlParts.size].each{ |p| t+=p+"/" ""}
                url=s+t
            end
            if (@lists.subStrings.any? { |word| url.include?(word)})
				return "Advertising"
			elsif (@lists.rtbCompanies.any? { |word| url.downcase.include?(word)})
                return "Advertising"
			elsif @lists.manualCats[host]!=nil
				return @lists.manualCats[host]
			end
            return nil
        end
    end

    def is_Ad_param?(params)
        if (params[0].downcase.eql? "type" and params[1].include? "ad")
            return true
        else
            return (@lists.adInParam.any? {|word| params[0].downcase.include?(word)})
        end
    end

#-----------------------------------------------------------------------------------

private

	def findCategory(host,domain,tld,lastPublisher)
		cat=nil
        if result=@lists.disconnect[host]                # APPLY FILTER
            cat=result.split("#")[0]
        elsif (host.count('.')>1 && result=@lists.disconnect[domain+"."+tld])      # APPLY FILTER NOT IN SUBDOMAIN
			host=domain+"."+tld
            cat=result.split("#")[0]
		end
		if @lists.sameParty[host]!=nil and @lists.sameParty[lastPublisher]!=nil
			if cat=="Content" and @lists.sameParty[host]==@lists.sameParty[lastPublisher]	#whitelist same parties
				return "Other"	
			end
		end
		return cat
	end

    def is_1pixel_image?(url)
		isthere=@db.get(@defines.beaconDBTable,"singlePixel","url",url)
		if isthere!=nil		# I've already seen that url 
			return (isthere.first.to_s == "1") if isthere.kind_of?(Array)
			return (isthere.to_s == "1")
		else	# no... wget it
			begin
				pixels=FastImage.size("http://"+url)
			    if pixels==[1,1]         # 1x1 pixel
					@db.insert(@defines.beaconDBTable,[url,1])
			        return true
				else
					@db.insert(@defines.beaconDBTable,[url,0])
			        return false
			   	end
			rescue Exception => e  
				if not e.message.include? "Network is unreachable"
					Utilities.warning "is_1pixel_image: "+e.message+"\n"+url  
					@db.insert(@defines.beaconDBTable,[url,0])
				end
			end				
		end			
        return false
    end
end
