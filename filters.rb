require 'fastimage'
load 'keywordsLists.rb'

class Filters

	def initialize(defs)
		@defines=defs
		@publishers=Hash.new(nil)
		@latency=Array.new
		@lastPub=Hash.new(nil)
		if @defines!=nil
			@lists=KeywordsLists.new(@defines.resourceFiles["filterFile"],@defines)
			@rtbMacros=@lists.rtbMacros
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

	def is_it_ID?(paramPair)
		alfa,digit=Utilities.digitAlfa(paramPair.last)
		return true if paramPair.last!=nil and not (paramPair.last.size<17 or (["http","utf","www","text","image"].any? { |word| paramPair.last.downcase.include?(word)})) and digit>3 and alfa>4 and not paramPair.first.include? "url" and not paramPair.last.include? "%" and not paramPair.last.include? "." and not paramPair.last.include? ";" and not paramPair.first.size>20 and not paramPair.last.include? "/" and not paramPair.last.include? "," and not paramPair.first=="X-Plex-Token"
		return false
	end

	def getTypeOfContent(url,httpContent)
		#Find content type from filetype
		type=-1
		return type if url==nil or url==-1
		temp=url.split("?").first.split("/")
		if temp.size>1	 
			temp2=temp.last.split(".")
			if temp2.size>1
				temp=temp2.last.split("%").first
				if temp!=nil and temp!=""
					temp2=temp.split("#").first
					if temp2!=nil and temp2!=""
						temp=temp2.split("&").first
						if temp!=nil and temp!=""					
							temp2=temp.split("$").first
							if temp2!=nil and temp2!=""
								fileEnd=temp2.split("@").first
		  						type=@lists.filetypes["."+fileEnd]
								return type if type!=nil
							end
						end
					end
				end
			end
		end
		if httpContent!=nil
			#Fallback to HTTP content field
			t1=httpContent.split(";")[0]
			type=t1.split(":")[0].gsub(" ","").downcase
			return @lists.types[type] if @lists.types[type]!=nil
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
		return false if not @defines.options["detectBeacons?"]
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
		if (str[1]==nil or str[0].eql? "v" or str[0].downcase.include? "ver" \
                or str[0].eql? "density" or str[0].eql? "u_sd" \
				or str[1].include? "," or str[1].include? "{" or str[1].include? "}" \
				or (["startapp","pkg","v-vice","button_icon","posts","read","text","image"].any? { |word| str[1].downcase.include?(word)}))
			return true
		end
		return false
	end

    def has_PriceKeyword?(param)            # Check if there is a price-related keyword and return the price
       return (@lists.keywords.any? { |word| param[0].downcase.eql?(word)})# and is_numeric?(param[1]))
    end


	def lookForRTBentitiesAndSize(urlStr,host)
		adx=-1;ssp=-1;dsp=-1;size=-1;carrier=-1;position=-1;
		adx=findInURL(urlStr,@rtbMacros["adx"],host,false)
		adx=host if adx==-1
		position=findInURL(urlStr,@rtbMacros["position"],host,false)
		dsp=findInURL(urlStr,@rtbMacros["dsp"],host,false)
		dsp=secondChanceDSP(urlStr) if dsp==-1
		publisher=findInURL(urlStr,@rtbMacros["pubs"],host,false)
		ssp=findInURL(urlStr,@rtbMacros["ssp"],host,false)
		size=findInURL(urlStr,@rtbMacros["sizes"],host,false)
		size=-1 if size!=-1 and (size.include? "." or not size.downcase.include? "x")
		w=-1;h=-1;
		carrier=findInURL(urlStr,"carrier",nil,false)
		carrier=findInURL(urlStr,"connection",nil,false) if carrier==-1
		if size==-1
			w=findInURL(urlStr,"w",nil,true)
			h=findInURL(urlStr,"h",nil,true)
			if w!=-1 and h!=-1 and Utilities.is_numeric?("w") and Utilities.is_numeric?("h")
				w=findInURL(urlStr,"width",nil,true)
				h=findInURL(urlStr,"height",nil,true)
			end
			size=w+"x"+h if w!=-1 and h!=-1 and Utilities.is_numeric?(w) and Utilities.is_numeric?(h)
		end
		if position==-1
			position=findInURL(urlStr,"pos",nil,true)
		end
		dsp=Utilities.calculateHost(dsp,nil).split(".").first if dsp!=-1
		ssp=Utilities.calculateHost(ssp,nil).split(".").first if ssp!=-1
		adx=Utilities.calculateHost(adx,nil).split(".").first if adx!=-1
		publisher=Utilities.calculateHost(publisher,nil).split(".").first if publisher!=-1
		return dsp, ssp, adx, publisher, size.to_s.downcase, carrier.to_s.downcase, position.to_s.downcase
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

	def findInURL(uri,array,host,lookForsize)
		delimiter="&"; equal="=";
		equal=":" if host=="mediasmart.es"
		url=uri.force_encoding("ISO-8859-1").split("?").last
		url=URI.unescape(url)
		encryptedTag="ecrypted"
		delimiter="," if equal==":"
		paramsArray=nil
		if host==nil
			paramsArray=array
		else
			array.keys.each{ |word| (paramsArray=array[word];break) if host.downcase.include?(word)}
		end
#this loop must be merged with the priceDetection procedure in core.rb
		if paramsArray!=nil
			url.split(delimiter).each{|param| paramName=param.split(equal)
				if paramName.size>1
					if not paramsArray.kind_of?(String)
						if paramsArray.any?{|param| param==paramName.first.downcase}
							res=Utilities.prepareParam(paramName[1]).downcase
							return -1 if paramName.size<2
							return encryptedTag if is_it_Encrypted?(res)
							return res if lookForsize or not Utilities.is_numeric?(res) 
						end
					else
						if paramsArray==paramName.first.downcase
							res=Utilities.prepareParam(paramName[1])
							return -1 if paramName.size<2 or res==nil
							res=res.downcase
							return encryptedTag if is_it_Encrypted?(res)
							return res if lookForsize or not Utilities.is_numeric?(res)
						end
					end
				end}
		end
		return -1
	end

	def secondChanceDSP(urlStr)
		url=urlStr.split("?").first
		dsp=-1
		dsp="mopub.com" if (url.include? "notify/mopub" or url.include? "won_mopub" or url.include? "mopub_nurl" or url.include? "mopubwinrtb" or url.include? "mopub.web")
		dsp=url.split("/rtbads/").last.split("/").last if dsp==-1 and (url.include? "/rtbads/")
		dsp="rubicon" if dsp==-1 and (url.include? "rubicon.web")
		dsp=url.split("taptapnetworks.com/ad/").last if dsp==-1 and (url.include? "taptapnetworks.com/ad/")
		dsp="nexage" if dsp==-1 and (url.include? "win/nexagertb")
		dsp="google" if dsp==-1 and (url.include? "win/google")
		dsp=url.split("adsrvr.org/bid/feedback/").last if dsp==-1 and (url.include? "adsrvr.org/bid/feedback/")
		dsp=url.split("avazutracking.net/price/").last if dsp==-1 and (url.include? "avazutracking.net/price/")
		dsp=url.split("/bid/feedback/").last if dsp==-1 and (url.include? "/bid/feedback/")
		return dsp
	end

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

	def is_it_Encrypted?(str)
		alfa,digit=Utilities.digitAlfa(str)
		return true if alfa>4 and digit>4 and str.size>10
		return false
	end

    def is_1pixel_image?(url)
		isthere=@db.get(@defines.beaconDBTable,"singlePixel","url",url)
		if isthere!=nil		# I've already seen that url 
			return (isthere.first.to_s == "1") if isthere.kind_of?(Array)
			return (isthere.to_s == "1")
		else	# no... wget it
			begin
				pixels=FastImage.size("http://"+url, :timeout=>0.7)
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
