load 'trace.rb'
load 'filters.rb'
load 'columnsFormat.rb'
load 'database.rb'

class Core
	attr_writer :window, :cwd
   	@isBeacon=false

	def initialize(defs,fullParse)
		@defines=defs
		@filters=Filters.new(@defines)		
		@trace=Trace.new(@defines)
		@window=-1
		@cwd=nil
		@adFilter=@filters.loadExternalFilter()
	end

	def getTrace
		return @trace
	end

	def getRows
		return @trace.rows
	end

    def loadRows(filename)
	makeDirsFiles()
	puts "> Name of input file: "+filename
        f=File.new(filename,'r')
        line=f.gets     #get rid of headers
        while(line=f.gets)
			h=Format.columnsFormat(line,@defines.column_Format)
			if h['host'].size>1 and h['host'].count('.')>0
		        		@trace.rows.push(h)
			end
        end
        f.close
        return @trace.rows
    end

	def parseRequest(row,quick,browserOnly)
		@curUser=row['IPport']
		if @trace.users[@curUser]==nil		#first seen user
			@trace.users[@curUser]=User.new	
		end

		if quick==true
			pricesOnly(row)
		else
			#CHECK THE DEVICE TYPE
			mob,dev,browser=reqOrigin(row)
			if browserOnly and not browser
				return -1
			end
			#FILTER ROW
			filterRow(mob,dev,browser,row)
		end
		return 1
	end

	def close
		@fn.close;@fu.close;@fnp.close;@fpub.close#@fl.close;@fbt.close;@fp.close;@fb.close;@fi.close; @fa.close; 
	end

	def perUserAnalysis
		puts "> Per user analysis..."
		@fu.puts "ID;Advertising;AdExtra;Analytics;Social;Content;noAdBeacons;Other;3rdSize(avgPerReq);3rdSize(sum);Ad-content;NumOfPrices;AdNumOfParams(min);AdNumOfParams(max);AdNumOfParams(avg);RestNumOfParams(min);RestNumOfParams(max);RestNumOfParams(avg);adBeacons;Impressions"
		for id,user in @trace.users do
			type3rd=user.filterType
			paramsStats=Utilities.makeStats(user.restNumOfParams)
			adParamsStats=Utilities.makeStats(user.adNumOfParams)
			sizeStats=Utilities.makeStats(user.sizes3rd)
			@fu.puts id+";"+user.row3rdparty['Advertising'].size.to_s+";"+user.row3rdparty['AdExtra'].size.to_s+";"+user.row3rdparty['Analytics'].size.to_s+";"+user.row3rdparty['Social'].size.to_s+";"+user.row3rdparty['Content'].size.to_s+";"+user.row3rdparty['Beacons'].size.to_s+";"+user.row3rdparty['Other'].size.to_s+";"+sizeStats['avg'].to_s+";"+sizeStats['sum'].to_s+";"+user.ads.length.to_s+";"+user.dPrices.length.to_s+";"+adParamsStats['min'].to_s+";"+adParamsStats['max'].to_s+";"+adParamsStats['avg'].to_s+";"+paramsStats['min'].to_s+";"+paramsStats['max'].to_s+";"+paramsStats['avg'].to_s+";"+user.adBeacon.to_s+";"+user.imp.length.to_s
			@database.insert(@define.userTable,id+","+user.row3rdparty['Advertising'].size+","+user.row3rdparty['AdExtra'].size+","+user.row3rdparty['Analytics'].size+","+user.row3rdparty['Social'].size+","+user.row3rdparty['Content'].size+","+user.row3rdparty['Beacons'].size+","+user.row3rdparty['Other'].size+","+sizeStats['avg'],sizeStats['sum']+","+user.ads.length+","+user.dPrices.length+","+adParamsStats['min']+","+adParamsStats['max']+","+adParamsStats['avg']+","+paramsStats['min']+","+paramsStats['max']+","+paramsStats['avg']+","+user.adBeacon+","+user.imp.length)
		end
	end

	def readUserAcrivity(tmlnFiles)
		puts "> Loading "+tmlnFiles.size.to_s+" User Activity files..."
		user_path=@cwd+@defines.userDir
		timeline_path=@cwd+@defines.userDir+@defines.tmln_path
		for tmln in tmlnFiles do
			if not tmln.eql? '.' and not tmln.eql? ".." and not File.directory?(user_path+tmln)
				fr=File.new(user_path+tmln,'r')
				fw=nil
				firstTime=-1
				bucket=0
				startBucket=-1
				endBucket=-1
				c=0
				while line=fr.gets
					r=Format.columnsFormat(line,@defines.column_Format)
					mob,dev,browser=reqOrigin(r)
					if browser
						if firstTime==-1
							fw=File.new(timeline_path+tmln+"_per"+@window.to_s+"msec",'w')
							firstTime=r['tmstp'].to_i
							startBucket=firstTime
						end
						nbucket=applyTimeWindow(firstTime,r,fw)
						if bucket!=nbucket						
							fw.puts "\n"+startBucket.to_s+" : "+endBucket.to_s+"-> BUCKET "+bucket.to_s
							fw.puts Utilities.results_toString(@trace,false)+"\n"
							bucket=nbucket
							@trace=Trace.new(@defines)
							startBucket=r['tmstp']
						end
						@curUser=r['IPport']
						if @trace.users[@curUser]==nil		#first seen user
							@trace.users[@curUser]=User.new	
						end
						filterRow(mob,dev,browser,r)
						@trace.rows.push(r)
						fw.puts c.to_s+") BUCKET "+bucket.to_s+"\t"+r['tmstp']+"\t"+r['url']+"\t"+r['ua']
						endBucket=r['tmstp'].to_i
						c+=1
					end
				end
				if startBucket!=-1 && endBucket!=-1
					fw.puts "\n"+startBucket.to_s+" : "+endBucket.to_s+"-> BUCKET "+bucket.to_s
					fw.puts Utilities.results_toString(@trace,false)+"\n"
				end
				@trace=Trace.new(@defines)
				fr.close;
				if fw!=nil
					fw.close
				end
			end
		end
	end

	def createTimelines()
		puts "> Contructing User Timelines..."
		user_path=@cwd+@defines.userDir
		timeline_path=@cwd+@defines.userDir+@defines.tmln_path
		fr=File.new(@cwd+@defines.dataDir+"IPport_uniq",'r')
		while l=fr.gets
			user=l.chop
			fw=File.new(timeline_path+user+"_per"+(@window/1000).to_s+"sec",'w')
			IO.popen('grep '+user+' ./'+@defines.traceFile) { |io| 
			firstTime=-1
			while (line = io.gets) do 
				h=Format.columnsFormat(line,@defines.column_Format)
				Utilities.separateTimelineEvents(h,user_path+h['IPport'],@defines.column_Format)
				if firstTime==-1
					firstTime=h['tmstp'].to_i
				end
				applyTimeWindow(firstTime,row,fw)
			end }
			fw.close
		end
		fr.close
	end


#------------------------------------------------------------------------------------------------


	private

	def applyTimeWindow(firstTime,row,fw)
		diff=row['tmstp'].to_i-firstTime
		wnum=diff.to_f/@window.to_i
		return wnum.to_i
	end

	def pricesOnly(row)
		url=row['url'].split("?")
		if (url[1]==nil)
     		return 0,false
    	end
        fields=url[1].split('&')
        for field in fields do
            keyVal=field.split("=")
            if(not @filters.is_GarbageOrEmpty?(keyVal))
				if(detectPrice(keyVal,row['host']))
					Utilities.printRow(row,File.new(@defines.dirs['rootDir']+"PriceAds.out",'a'))
				end
			end
		end
	end	

	def reqOrigin(row)
		#CHECK IF ITS MOBILE USER
		mob,dev=@filters.is_MobileType?(row)   # check the device type of the request
		if mob
			@trace.mobDev+=1
		end
		#CHECK IF ITS ORIGINATED FROM BROWSER
		browser=@filters.is_Browser?(row,dev)
		if browser
			@trace.fromBrowser.push(row)
		end
        @trace.devs.push(dev)
		return mob,dev,browser
	end		

	def filterRow(mob,dev,browser,row)
		url=row['url'].split("?")
		host=row['host']
		isPorI,noOfparam=beaconImprParamCkeck(url,row)
		iaAdinURL=false
		type3rd=@filters.is_Ad?(url[0],host,@adFilter)
		if type3rd!=nil	#	3rd PARTY CONTENT
			@trace.users[@curUser].row3rdparty[type3rd].push(row)
			@trace.party3rd[type3rd]+=1
			if not type3rd.eql? "Content"
				if	type3rd.eql? "Advertising"
					ad_detected(row,noOfparam,mob,dev,url)
				end
				#CALCULATE SIZE
				sz=row['length']
				@trace.users[@curUser].sizes3rd.push(sz.to_i)
				@trace.sizes.push(sz.to_i)
			end
		else		
			if @isBeacon 	#Beacon NOT ad-related
				@trace.users[@curUser].row3rdparty["Beacons"].push(row)
			elsif isPorI>0	# Impression or ad in param
				@trace.users[@curUser].row3rdparty["AdExtra"].push(row)
				ad_detected(row,noOfparam,mob,dev,url)
				@trace.party3rd["Advertising"]+=1
			elsif isPorI<1	# Rest
				@trace.users[@curUser].row3rdparty["Other"].push(row)
				@trace.party3rd["Other"]+=1
				@trace.users[@curUser].restNumOfParams.push(noOfparam.to_i)
				@trace.publishers.push(row['url'])
				#Utilities.printStrippedURL(url,@fl)	# dump leftovers
			end
		end
	end

	def makeDirsFiles		
		@database=Database.new(@defines.dirs['rootDir']+@defines.traceFile+".db")
		@database.create(@defines.impTable, 'timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR ,url VARCHAR PRIMARY KEY, Host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER')
		@database.create(@defines.adsTable, 'timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR ,url VARCHAR PRIMARY KEY, Host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER')
		@database.create(@defines.bcnTable, 'timestamp BIGINT, ip_port VARCHAR, userIP VARCHAR ,url VARCHAR PRIMARY KEY, host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER, beaconType VARCHAR')
		@database.create(@defines.priceTable, 'host VARCHAR, priceTag VARCHAR, priceValue VARCHAR')
		@database.create(@defines.userTable, 'id VARCHAR PRIMARY KEY, advertising INTEGER, adExtra INTEGER, analytics INTEGER, social INTEGER, content INTEGER, noAdBeacons INTEGER, other INTEGER, thirdPartySize_avgPerReq FLOAT, thirdPartySize INTEGER, adcontent INTEGER, numOfPrices INTEGER, adNumOfParams_min INTEGER, adNumOfParams_max INTEGER, adNumOfParams_avg FLOAT, restNumOfParams_min INTEGER, restNumOfParams_max INTEGER, restNumOfParams_avg FLOAT, adBeacons INTEGER, impressions INTEGER')


		print "> Creating Directories... "
		Dir.mkdir @defines.dirs['rootDir'] unless File.exists?(@defines.dirs['rootDir'])
		Dir.mkdir @defines.dirs['dataDir'] unless File.exists?(@defines.dirs['dataDir'])
		Dir.mkdir @defines.dirs['adsDir'] unless File.exists?(@defines.dirs['adsDir'])
		Dir.mkdir @defines.dirs['userDir'] unless File.exists?(@defines.dirs['userDir'])
		Dir.mkdir @defines.dirs['timelines'] unless File.exists?(@defines.dirs['timelines'])
		puts "and files..."
        #@fi=File.new(@defines.files['impFile'],'w')
        #@fa=File.new(@defines.files['adfile'],'w')
        @fl=File.new(@defines.files['leftovers'],'w')
        #@fp=File.new(@defines.files['prices'],'w')
		@fpub=File.new(@defines.files['publishers'],'w')
        @fn=File.new(@defines.files['paramsNum'],'w')
        #@fb=File.new(@defines.files['bcnFile'],'w')
        @fd2=File.new(@defines.files['adDevices'],'w')
        #@fbt=File.new(@defines.files['beaconT'],'w')
		#@fu=File.new(@defines.files['userFile'],'w')
		@fnp=File.new(@defines.files['priceTagsFile'],'w')
	end

    def detectPrice(keyVal,domainStr);          	# Detect possible price in parameters and returns URL Parameters in String
		domain,tld=Utilities.tokenizeHost(domainStr)
		host=domain+"."+tld
		if (@filters.is_inInria_PriceTagList?(host,keyVal) or @filters.has_PriceKeyword?(keyVal)) 		# Check for Keywords and if there aren't any make ad-hoc heuristic check
			priceTag=keyVal[0]
			priceVal=keyVal[1]
			@database.insert(@defines.priceTable, host+","+priceTag+","+priceVal)
			if (Utilities.is_numeric?(keyVal[1]) and @fnp!=nil)
				@fnp.puts host+"\t"+keyVal[0].downcase
			end
			@trace.users[@curUser].dPrices.push(keyVal[1])
			@trace.detectedPrices.push(keyVal[1])
			return true
		end
		return false
    end

    def detectImpressions(url,row);     	#Impression term in path
        if @filters.is_Impression?(url[0])
			Utilities.printRowToDB(row,@database,@defines.impTable,nil)
			@trace.totalImps+=1
		    @trace.users[@curUser].imp.push(row)
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
            if(not @filters.is_GarbageOrEmpty?(keyVal))
				if(@filters.is_Beacon_param?(keyVal) and not @isBeacon)
					beaconSave(url[0],row)
				end
				if(detectPrice(keyVal,row['host']))
					if @trace.fromBrowser.include? row					
						@trace.browserPrices+=1
					end
				#	Utilities.printRow(row,File.new(@defines.dirs['rootDir']+"PriceAds.out",'a'))
					isAd=true
				end
				if(@filters.is_Ad_param?(keyVal))
					isAd=true
				end
			end
		end
		return fields.length,isAd
	end
			
	def beaconSave(url,row)         #findBeacons
		@isBeacon=true
		urlStr=url.split("%")[0].split(";")[0]
		@trace.party3rd["totalBeacons"]+=1
		temp=urlStr.split("/")	   #beacon type
		words=temp.size
		slashes=urlStr.count("/")
		last=temp[temp.size-1]
        temp=last.split(".")
		if (temp.size==1 or words==slashes)
			type="other"
        else
			last=temp[temp.size-1]
        	type=last
		end
		Utilities.printRowToDB(row,@database,@defines.bcnTable,type)
	end

	def beaconImprParamCkeck(url,row) 
        @isBeacon=false
		isAd=-1
        if (@filters.is_Beacon?(url[0]))  		#findBeacon in URL
            isAd=0
            beaconSave(url[0],row)
        end
        paramNum, result=checkParams(row,url)             #find ads
        if(result==true or detectImpressions(url,row))
            isAd=1
		end
		return isAd,paramNum
	end

	def ad_detected (row,noOfparam,mob,dev,url)
        @trace.users[@curUser].ads.push(row)
        @trace.users[@curUser].adNumOfParams.push(noOfparam.to_i)
		@trace.totalParamNum.push(noOfparam)
		if @fn!=nil
			@fn.puts noOfparam
		end
		if (@isBeacon)			#is it ad-related Beacon?
			@trace.users[@curUser].adBeacon+=1
			@trace.totalAdBeacons+=1
			@isBeacon=false
		end
		if(mob)
			@trace.numOfMobileAds+=1
		end
	#	@fd2.puts(dev)	#adRelated Devices
        Utilities.printRowToDB(row,@database,@defines.adsTable,nil)
	end
end
