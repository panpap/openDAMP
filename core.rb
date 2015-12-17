require 'trace'
require 'filters'

class Core
   	@@isBeacon=false
	@@filters=Filters.new
	@@adFilter=nil
	@@utils=Utilities.new

	def initialize 
	puts "> Creating Directories..."
		Dir.mkdir @@rootDir unless File.exists?(@@rootDir)
        Dir.mkdir @@dataDir unless File.exists?(@@dataDir)
        Dir.mkdir @@adsDir unless File.exists?(@@adsDir)
		Dir.mkdir @@userDir unless File.exists?(@@userDir)
        @fi=File.new(@@impFile,'w')
        @fa=File.new(@@adfile,'w')
        @fl=File.new(@@leftovers,'w')
        @fp=File.new(@@prices,'w')
        @fn=File.new(@@paramsNum,'w')
        @fd1=File.new(@@devices,'w')
        @fb=File.new(@@bcnFile,'w')
        @fz=File.new(@@size3rdFile,'w')
        @fd2=File.new(@@adDevices,'w')
        @fbt=File.new(@@beaconT,'w')
		@fu=File.new(@@userFile,'w')
		@clients=Hash.new
		@numOfBeacons=0
		@trace=Trace.new
	end
	
	def getTrace
		return @trace
	end

	def getRows
		return @trace.rows
	end

    def loadRows(filename)
        f=File.new(filename,'r')
        line=f.gets     #get rid of headers
        while(line=f.gets)
            h = Hash.new(-1)
            part=line.chop.split("\t")
            h['IPport']=part[0]
            h['uIP']=part[1]
            h['url']=part[2]
            h['ua']=part[3]
            h['host']=part[4]
            h['tmstp']=part[5]
            h['status']=part[6]
            h['length']=part[7]
            h['dataSz']=part[8]
            h['dur']=part[9]
            h['HtorM']=part[10]
            @trace.rows.push(h)
        end
        f.close
@@adFilter=@@filters.loadExternalFilter
        return @trace.rows
    end

    def separateField(att);
        puts "> Separate files and calculate instances for "+att
	path=@@dataDir+att
        fw=File.new(path,'w')
        for r in @trace.rows do
            fw.puts r[att]
        end
		@@utils.countInstances(path)
        fw.close
    end

	def parseRequest(row)
		url=row['url'].split("?")
		host=row['host']
		@@curUser=row['IPport']
		if @trace.users[@@curUser]==nil		#first seen user
			@trace.users[@@curUser]=User.new	
		end

		#CHECK IF ITS MOBILE USER
		mob,dev=@@filters.is_MobileType?(row)   # check the device type of the request
		if mob
			@trace.mobDev+=1
		end
        @fd1.puts dev

		#FILTER ROW
		isPorI,noOfparam=beaconImprParamCkeck(url,row)
		iaAdinURL=false
		type3rd=@@filters.is_Ad?(url[0],host,@@adFilter)
        if(type3rd!=nil)
			@trace.users[@@curUser].row3rdparty[type3rd].push(row)
            @trace.users[@@curUser].adsType["adInUrl"]+=1
            @trace.users[@@curUser].filterType[type3rd]+=1
			@trace.party3rd[type3rd]+=1
			if not type3rd.eql? "Content"
				if type3rd.eql? "Advertising"
					isAdinURL=true
				end
				#CALCULATE SIZE
				sz=row['length']
				@fz.puts sz
				@trace.users[@@curUser].sizes3rd.push(sz.to_i)
				@trace.sizes.push(sz.to_i)
			end
		elsif(type3rd==nil and isPorI<1 and @@isBeacon==false)
			@trace.users[@@curUser].row3rdparty["other"].push(row)
		end
		if(isAdinURL or isPorI>0)
			if (type3rd==nil and isPorI>0)
				@trace.users[@@curUser].row3rdparty["AdExtra"].push(row)
			end
            @trace.users[@@curUser].ads.push(row)
            @trace.users[@@curUser].paramNum.push(noOfparam.to_i)
			@trace.totalParamNum.push(noOfparam)
			@trace.totalNumOfAds+=1
			@fn.puts noOfparam
			if (@@isBeacon)			#is it ad-related Beacon?
				@trace.users[@@curUser].adBeacon+=1
				@trace.totalAdBeacons+=1
				@@isBeacon=false
			end
			if(mob)
				@trace.numOfMobileAds+=1
			end
			@fd2.puts(dev)
            @@utils.printStrippedURL(url,@fa)
		elsif(not @@isBeacon and type3rd==nil)	#no beacon||no imp||no third party => leftovers
			@@utils.printStrippedURL(url,@fl)
		else
			#Analytics/Social/Beacons do nothing
		end
	end

	def close
		@fbt.close;@fp.close;@fb.close;@fz.close;@fi.close; @fa.close; @fl.close;@fn.close;@fd1.close;@fd2.close;@fu.close
	end

	def perUserAnalysis
		puts "> Per user analysis..."
		@fu.puts "ID;Advertising;AdExtra;Analytics;Social;Content;other;3rdSize(avgPerReq);3rdSize(sum);Ad-content;NumOfPrices;NumOfParams(min);NumOfParams(max);NumOfParams(avg);Beacons;adBeacons;Impressions"
		for id,user in @trace.users do
			type3rd=user.filterType
			@fu.print id+";"+type3rd['Advertising'].to_s+";"+type3rd['Analytics'].to_s+";"+type3rd['Social'].to_s+";"+type3rd['Content'].to_s+";"
			paramsStats=@@utils.makeStats(user.paramNum)
			sizeStats=@@utils.makeStats(user.sizes3rd)
			@fu.print sizeStats['avg'].to_s+";"+sizeStats['sum'].to_s+";"+user.ads.length.to_s+";"+user.dPrices.length.to_s+";"+paramsStats['min'].to_s+";"+paramsStats['max'].to_s+";"+paramsStats['avg'].to_s+";"+user.beacons.length.to_s+";"+user.adBeacon.to_s+";"+user.imp.length.to_s

			@fu.print ";"+user.row3rdparty['Advertising'].size.to_s+";"+user.row3rdparty['AdExtra'].size.to_s+";"+user.row3rdparty['Analytics'].size.to_s+";"+user.row3rdparty['Social'].size.to_s+";"+user.row3rdparty['Content'].size.to_s+";"+user.row3rdparty['other'].size.to_s+"\n"
			if id=="5.56.61.185:11879"
				user.row3rdparty['Content'].each {|row| puts "> "+row['url']}
			end
		end
	end



#------------------------------------------------------------------------------------------------



	private

    def detectPrice(keyVal,domain);          	# Detect possible price in parameters and returns URL Parameters in String 
		if (@@filters.has_PriceKeyword?(keyVal)) 		# Check for Keywords and if there aren't any make ad-hoc heuristic check
          	@fp.puts keyVal[0]+"\t"+keyVal[1]+"\t"+domain
			@trace.users[@@curUser].dPrices.push(keyVal[1])
			@trace.detectedPrices.push(keyVal[1])
			return true
		end
		return false
    end

    def detectImpressions(url,row);     	#Impression term in path
        if @@filters.is_Impression?(url[0])
			@@utils.printRow(row,@fi)
			@trace.totalImps+=1
		    @trace.users[@@curUser].imp.push(row)
			return true
        end
		return false
    end

	def checkParams(row,url)
     	if (url[1]==nil)
     		return 0,false
    	end
		isAd=false
        fields=url[1].split('&')
        for field in fields do
            keyVal=field.split("=")
            if(not @@filters.is_GarbageOrEmpty?(keyVal))
				if(@@filters.is_Beacon_param?(keyVal) and not @@isBeacon)
					beaconSave(url[0],row)
				end
				if(detectPrice(keyVal,row['host']))
					isAd=true
				end
				if(@@filters.is_Ad_param?(keyVal))
					isAd=true
				end
			end
		end
		return fields.length,isAd
	end
			
	def beaconSave(url,row)         #findBeacons
		@@isBeacon=true
    	@trace.users[@@curUser].beacons.push(row)
		@trace.totalBeacons+=1
		@@utils.printRow(row,@fb)
		urlStr=url.split("%")[0].split(";")[0]

		temp=urlStr.split("/")	   #beacon type
		words=temp.size
		slashes=urlStr.count("/")
		last=temp[temp.size-1]
        temp=last.split(".")
		if (temp.size==1 or words==slashes)
			@fbt.puts "other"
        else
			last=temp[temp.size-1]
        	@fbt.puts last
		end
	end

	def beaconImprParamCkeck(url,row) 
        @@isBeacon=false
		isAd=-1
        if (@@filters.is_Beacon?(url[0],url[1]))  		#findBeacon in URL
            isAd=0
            beaconSave(url[0],row)
        end
        paramNum, result=checkParams(row,url)             #find ads
        if(result)
            isAd=1
            @trace.users[@@curUser].adsType['params']+=1
        end
        if(detectImpressions(url,row))
            isAd=1
            @trace.users[@@curUser].adsType["imp"]+=1
        end
		return isAd,paramNum
	end
end
