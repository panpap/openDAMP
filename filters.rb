require 'fastimage'
require 'rubygems'
require 'json'

class Filters
		@@beacon_key=["beacon","pxl","pixel","adimppixel","data.gif","px.gif","pxlctl"]

		@@imps=["impression","_imp","/imp","imp_"]

		@@keywords=["price","pp","pr","bidprice","bid_price","bp","winprice", "computedprice", "pricefloor",
		               "win_price","wp","chargeprice","charge_price","cp","extcost","tt_bidprice","bdrct",
		               "ext_cost","cost","rtbwinprice","rtb_win_price","rtbwp","bidfloor","seatbid"]

		@@inria={ "rfihub.net" => "ep","invitemedia.com" => "cost",#,"scorecardresearch.com" => "uid" 
				"ru4.com" => "_pp","tubemogul.com" => "x_price", "invitemedia.com" => "cost", 
			"tubemogul.com" => "price", #"bluekai.com" => "phint", 
			"adsrvr.org" => "wp",  
			"pardot.com" => "title","tubemogul.com" => "price","mathtag.com" => "price",
			"adsvana.com" => "_p", "doubleclick.net" => "pr", "ib.adnxs.com" => "add_code", 
			"turn.com" => "acp", "ams1.adnxs.com" => "pp",  "mathtag.com" => "price",
			"youtube.com" => "description1", "quantcount.com" => "p","rfihub.com" => "ep",
			"w55c.net" => "wp_exchange", "adnxs.com" => "pp", "gwallet.com" => "win_price",
			"criteo.com" => "z"}

		# ENHANCED BY ADBLOCK EASYLIST
		@@subStrings=["/Ad/","pagead","/adv/","/ad/","ads",".ad","rtb-","adwords","admonitoring","adinteraction",
					"adrum","adstat","adviewtrack","adtrk","/Ad","bidwon","/rtb"] #"market"]	

		@@rtbCompanies=["adkmob","green.erne.co","bidstalk","openrtb","eyeota","ad-x.co.uk","startappexchange.com","atemda.com",
				"qservz","hastrk","api-","clix2pix.net","exoclick","adition.com","yieldlab","trafficfactory.biz","clickadu",
				"waiads.com","taptica.com","mediasmart.es"]

		@@adInParam=["ad_","ad_id","adv_id","bid_id","adpos","adtagid","rtb","adslot","adspace","adUrl", "ads_creative_id", 
				"creative_id","adposition","bidid","adsnumber","bidder","auction","ads_",
				"adunit", "adgroup", "creativity","bid_","bidder_"]

		@@browsers=['dolphin', 'gecko', 'opera','webkit','mozilla','gecko','browser','chrome','safari']


	def initialize(defs)
		@defines=defs
		@latency=Array.new
		@db = Database.new(@defines,nil,@defines.beaconDB)
		@db.create(@defines.tables['beaconDBTable'],'url VARCHAR PRIMARY KEY, singlePixel BOOLEAN')
	end

	def close
		puts "CLOSING BEACON DB..."
		@db.close if db
	end

    def loadExternalFilter
       	file = File.read(@defines.files["filterFile"])
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
		temp=@@inria[domain]
		if temp!=nil and temp.downcase.eql? keyVal[0]
			return true
		end
		return false
	end

    def is_Beacon_param?(params)
        return (@@beacon_key.any? {|word| params[0].downcase.include?(word)})
    end

    def is_Beacon?(url)		
		if [".jpeg", ".gif", ".png" ,"bmp"].any? {|word| url.downcase.include?(word)}
		    if is_1pixel_image?(url)
				return true
		    elsif(@@beacon_key.any? { |word| url.include?(word)})
		        return true
		    end
		end
		return false
    end

	def is_Browser?(row)
		browser="unknown"			# IS APP... DO NOTHING
		ua=row['ua'].downcase
		@@browsers.any? { |word| browser=word if ua.include?(word) }     # IS BROWSER? 
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
        return (@@imps.any? { |word| url.downcase.include?(word)})
    end


	def is_GarbageOrEmpty?(str) #filter out version, density parameters
        return (str[1]==nil or str[0].eql? "v" or str[0].downcase.include? "ver" \
                    or str[0].eql? "density" or str[0].eql? "u_sd")
    end

    def has_PriceKeyword?(param)            # Check if there is a price-related keyword and return the price
 #      if param[0].eql? "latency"
 #           @latency.push(param[1].to_f)
 #           fa=File.new('./latency.out','a')
 #           fa.puts param[1]
 #           fa.close
 #      end
       return (@@keywords.any? { |word| param[0].downcase.eql?(word)})# and is_numeric?(param[1]))
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
            if (@@subStrings.any? { |word| url.include?(word)} or @@rtbCompanies.any? { |word| url.downcase.include?(word)})
                return "Advertising"
            end
            return nil
        end
    end

    def is_Ad_param?(params)
        if (params[0].downcase.eql? "type" and params[1].include? "ad")
            return true
        else
            return (@@adInParam.any? {|word| params[0].downcase.include?(word)})
        end
    end

#-----------------------------------------------------------------------------------

private

    def is_1pixel_image?(url)
        if [".jpeg", ".gif", ".png" ,"bmp"].any? {|word| url.downcase.include?(word)} #IS IMAGE?
			isthere=@db.get(@defines.tables['beaconDBTable'],"singlePixel","url",url)
			if isthere!=nil		# I've already seen that url 
				return isthere == 1
			else	# no... wget it
				begin
					pixels=FastImage.size("http://"+url)
				    if pixels==[1,1]         # 1x1 pixel
						@db.insert(@defines.tables['beaconDBTable'],[url,1])
				        return true
					else
						@db.insert(@defines.tables['beaconDBTable'],[url,0])
				        return false
				   	end
				rescue Exception => e  
					if not e.message.include? "Network is unreachable"
						puts "is_1pixel_image: "+e.message
						puts url  
						@db.insert(@defines.tables['beaconDBTable'],[url,0])
					end
				end				
			end			
        end		
        return false
    end
end
