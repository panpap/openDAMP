require 'rubygems'
require 'json'

class Filters
        @@latency=Array.new
        def Filters.getLatency
                return @@latency
        end

        def Filters.loadExternalFilter
               	file = File.read(@@filterFile)
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

		def Filters.is_inInria_PriceTagList? (domain,keyVal)
			temp=@@inria[domain]
			if temp!=nil and temp.downcase.eql? keyVal[0]
				return true
			end
			return false
		end

        def Filters.is_Beacon_param?(params)
                return (@@beacon_key.any? {|word| params[0].downcase.include?(word)})
        end

        def Filters.is_Beacon?(url,params)
                if (url.downcase.include? ".htm" or url.downcase.include? ".xml")
                        return false
                elsif(@@beacon_key.any? { |word| url.include?(word)})
                        return true
                else
                    	return false
                end
        end

#def Filters.is_Browser?(row,type)
#	ua=row['ua'].downcase
#	if (type=="Macintosh" or type=="Windows" or type=="Linux" or type=="BSD") # IS DESKTOP?
#               return true
#	elsif (@@browsers.any? { |word| ua.include?(word)})     # IS BROWSER?
#               return true
#	else                                                    # IS APP... DO NOTHING
#               return false
#	end
#end

        def Filters.is_MobileType?(row)
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
                elseif ua.include? "macintosh"
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

        def Filters.is_Impression?(url)
                if (url.include? "impl") #junk
                        return false
                end
                return (@@imps.any? { |word| url.downcase.include?(word)})
        end


	def Filters.is_GarbageOrEmpty?(str) #filter out version, density parameters
                return (str[1]==nil or str[0].eql? "v" or str[0].downcase.include? "ver" \
                        or str[0].eql? "density" or str[0].eql? "u_sd")
        end

        def Filters.has_PriceKeyword?(param)            # Check if there is a price-related keyword and return the price
               if param[0].eql? "latency"
                        @@latency.push(param[1].to_f)
                        fa=File.new('./latency.out','a')
                        fa.puts param[1]
                        fa.close
               end
               return (@@keywords.any? { |word| param[0].downcase.eql?(word)})# and is_numeric?(param[1]))
        end

	def Filters.is_Ad?(url,host,filter)
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

        def Filters.is_Ad_param?(params)
                if (params[0].downcase.eql? "type" and params[1].include? "ad")
                        return true
                else
                        return (@@adInParam.any? {|word| params[0].downcase.include?(word)})
                end
        end
end
