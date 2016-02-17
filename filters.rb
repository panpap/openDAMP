require 'fastimage'
require 'rubygems'
require 'json'
load 'keywordsLists.rb'

class Filters

	def initialize(defs)
		@defines=defs
		@publishers=Hash.new(nil)
		@latency=Array.new
		@lastPub=Hash.new(nil)
		if @defines!=nil
			@lists=KeywordsLists.new(@defines.files["filterFile"])
			@db = Database.new(@defines,@defines.beaconDB)
			@cats=@lists.sameParty.keys
			@db.create(@defines.beaconDBTable,'url VARCHAR PRIMARY KEY, singlePixel BOOLEAN')
		end
	end

	def getCats
		return @cats+["Beacons","Other"]
	end

	def close
		puts "CLOSING BEACON DB..."
		@db.close if db
	end

	def getTypeOfContent(url,httpContent)
		#Find content type from filetype
		temp=url.split("?").first.split("/")
		if temp.size>1
			temp2=temp.last.split(".")
			if temp2.size>1				
				fileEnd=temp2.last.split("%").first.split("#").first.split("&").first.split("$").first.split("@").first
		  		type=@lists.filetypes["."+fileEnd]
				return type if type!=nil
			end
		end
		if httpContent!=nil
			#Fallback to HTTP content field
			t1=httpContent.split(";")[0]
			type=t1.split(":")[0].gsub(" ","").downcase
			return @lists.types[type]
		end
		return -1
	end

	def getReceiverType(host)
		return -1#@lists.adCompaniesCat[host]
	end

	def is_inInria_PriceTagList? (domain,keyVal)
		temp=@lists.inria[domain]
		if temp!=nil and temp.downcase.eql? keyVal[0]
			return true
		end
		return false
	end

 #   def is_Beacon_param?(params)
 #       return (@lists.beacon_key.any? {|word| params[0].downcase.include?(word)})
 #   end

    def is_Beacon?(url,type,force)
		if ([".jpeg", ".gif", ".png" ,".bmp"].any? {|word| url.downcase.include?(word)}) or type=="image" or force
		    return is_1pixel_image?(url)
		end
		if (@lists.beacon_key.any? { |word| url.include?(word)})
			return true		
		end
		return false
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


	def is_GarbageOrEmpty?(str) 
		return true if str==nil
		if str.kind_of?(Array) and (str[1]==nil or str[0].eql? "v" or str[0].downcase.include? "ver" \
                    or str[0].eql? "density" or str[0].eql? "u_sd")
			return true
		else
			return (str.size<17 or (["http","utf","www","text","image"].any? { |word| str.downcase.include?(word)}))
    	end
	end

    def has_PriceKeyword?(param)            # Check if there is a price-related keyword and return the price
       return (@lists.keywords.any? { |word| param[0].downcase.eql?(word)})# and is_numeric?(param[1]))
    end

	def getCategory(urlAll,host,user)
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
		cat,domain,tld=externalList(host,@lastPub[user])
        if cat!=nil
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

	def getRootHost(host,cat) 
		if cat==nil
			@cats.each{|c| res=@lists.sameParty[c][host]; if res!=nil
				return res.split("://").last.gsub("/","").gsub("www.","")
			end}
			return host
		else
			return @lists.sameParty[cat][host]
		end
	end


#-----------------------------------------------------------------------------------

private


	def externalList(host,lastPublisher)
		cat=nil
		domain,tld=Utilities.tokenizeHost(host)
        if result=@lists.disconnect[host]                # APPLY FILTER
            cat=result.split("#")[0]
        elsif (host.count('.')>1 && result=@lists.disconnect[domain+"."+tld])      # APPLY FILTER NOT IN SUBDOMAIN
			host=domain+"."+tld
            cat=result.split("#")[0]
		end
		if cat=="Content" and lastPublisher!=nil
			rootHostA=getRootHost(host,"Content")
			rootHostB=getRootHost(lastPublisher,"Content")
			if rootHostA!=nil and rootHostB!=nil and rootHostA==rootHostB	#whitelist same parties
				cat="Other"	
			end
		end
		return cat,domain,tld
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
