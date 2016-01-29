load 'trace.rb'
load 'filters.rb'
load 'database.rb'
load 'columnsFormat.rb'

class Core
	attr_writer :window, :cwd
	attr_accessor :database
   	@isBeacon=false

	def initialize(defs,options)
		@defines=defs
		@options=options
		@filters=Filters.new(@defines)		
		@trace=Trace.new(@defines)
		@window=-1
		@cwd=nil
		@database=nil
		@adFilter=@filters.loadExternalFilter()
	end
	
	def makeDirsFiles()
		print "> Creating Directories..., "
		Dir.mkdir @defines.dirs['rootDir'] unless File.exists?(@defines.dirs['rootDir'])
		if @options['detail']
			Dir.mkdir @defines.dirs['dataDir'] unless File.exists?(@defines.dirs['dataDir'])
			Dir.mkdir @defines.dirs['adsDir'] unless File.exists?(@defines.dirs['adsDir'])
			Dir.mkdir @defines.dirs['userDir'] unless File.exists?(@defines.dirs['userDir'])
			Dir.mkdir @defines.dirs['timelines'] unless File.exists?(@defines.dirs['timelines'])	
			puts "and database tables..."
			@database=Database.new(@defines.dirs['rootDir']+@defines.resultsDB,@defines,@options)
			@database.create(@defines.tables['publishersTable'], 'id VARCHAR PRIMARY KEY, timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR, url VARCHAR , Host VARCHAR, mobile VARCHAR, device INTEGER, browser INTEGER')
			#@database.create(@defines.tables['impTable'], 'id VARCHAR PRIMARY KEY,timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR, url VARCHAR, Host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER')
			@database.create(@defines.tables['adsTable'], 'id VARCHAR PRIMARY KEY, timestamp BIGINT, ip_Port VARCHAR, userIP VARCHAR, url VARCHAR, host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER,mob INTEGER,device VARCHAR,browser VARCHAR')
			@database.create(@defines.tables['bcnTable'], 'id VARCHAR PRIMARY KEY, timestamp BIGINT, ip_port VARCHAR, userIP VARCHAR, url VARCHAR, beaconType VARCHAR, mob INTEGER,device VARCHAR,browser VARCHAR')
			@database.create(@defines.tables['priceTable'], 'id VARCHAR PRIMARY KEY,timestamp BIGINT, host VARCHAR, priceTag VARCHAR, priceValue VARCHAR,type VARCHAR')
			@database.create(@defines.tables['userTable'], 'id VARCHAR PRIMARY KEY, advertising INTEGER, analytics INTEGER, social INTEGER, content INTEGER, noAdBeacons INTEGER, other INTEGER, avgDurationPerCategory VARCHAR, totalSizePerCategory VARCHAR, hashedPrices INTEGER, numericPrices INTEGER,adBeacons INTEGER, impressions INTEGER, publishersVisited INTEGER')
			@database.create(@defines.tables['traceTable'], 'id VARCHAR PRIMARY KEY, totalRows BIGINT, users INTEGER, advertising INTEGER, analytics INTEGER, social INTEGER, content INTEGER, beacons INTEGER, other INTEGER, thirdPartySize_total INTEGER, totalMobileReqs INTEGER, browserReqs INTEGER,mobileAdReqs VARCHAR, hashedPrices INTEGER, numericPrices INTEGER, adRelatedBeacons VARCHAR, numImpressions INTEGER')
			#@fnp=File.new(@defines.files['priceTagsFile'],'w')
		end
	end

	def analysis
		puts "> Stripping parameters, detecting and classifying Third-Party content..."
		fw=nil
		if @options['files']==1
			puts "> Dumping to files..."
			fd=File.new(@defines.files['devices'],'w')
			@trace.devs.each{|dev| fd.puts dev}
			fd.close
			fpar=File.new(@defines.files['restParamsNum'],'w')
			@trace.restNumOfParams.each{|p| fpar.puts p}
			fpar.close
			fpar=File.new(@defines.files['adParamsNum'],'w')
			@trace.adNumOfParams.each{|p| fpar.puts p}
			fpar.close
			fsz=File.new(@defines.files['size3rdFile'],'w')
			trace.sizes.each{|sz| fsz.puts sz}
			fsz.close
		end
		puts "> Calculating Statistics about detected ads..."
		puts @trace.results_toString(@database,@defines.tables['traceTable'],@defines.tables['bcnTable'])
		perUserAnalysis()
	end

	def findStrInRows(str)
		for val in r.values do
			if val.include? str
				if(printable)
					url=r['url'].split('?')
					Utilities.printRow(r,STDOUT)
				end
				found.push(r)					
				break
			end
		end
	end

	def parseRequest(row,browserOnly)
		@curUser=row['IPport']
		if @trace.users[@curUser]==nil		#first seen user
			@trace.users[@curUser]=User.new	
		end
		mob,dev,browser=reqOrigin(row)		#CHECK THE DEVICE TYPE
		row['mob']=mob
		row['dev']=dev
		row['browser']=browser
		if browserOnly and browser.eql? "unknown"
			return false
		else		#FILTER ROW
			filterRow(row)
			return true
		end
	end

	def readUserAcrivity(tmlnFiles)
		puts "> Loading "+tmlnFiles.size.to_s+" User Activity files..."
		user_path=@cwd+@defines.userDir
		timeline_path=@cwd+@defines.userDir+@defines.tmln_path
		for tmln in tmlnFiles do
			createTmlnForUser(tmln,timeline_path,user_path)
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

	def	createTmlnForUser(tmln,timeline_path,user_path)
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
				row['mob']=mob
				row['dev']=dev
				row['browser']=browser
				if browser!=nil
					if firstTime==-1
						fw=File.new(timeline_path+tmln+"_per"+@window.to_s+"msec",'w')
						firstTime=r['tmstp'].to_i
						startBucket=firstTime
					end
					nbucket=applyTimeWindow(firstTime,r,fw)
					if bucket!=nbucket						
						fw.puts "\n"+startBucket.to_s+" : "+endBucket.to_s+"-> BUCKET "+bucket.to_s
						fw.puts @trace.results_toString(@database,nil,nil)+"\n"
						bucket=nbucket
						@trace=Trace.new(@defines)
						startBucket=r['tmstp']
					end
					@curUser=r['IPport']
					if @trace.users[@curUser]==nil		#first seen user
						@trace.users[@curUser]=User.new	
					end
					filterRow(r)
					@trace.rows.push(r)
					fw.puts c.to_s+") BUCKET "+bucket.to_s+"\t"+r['tmstp']+"\t"+r['url']+"\t"+r['ua']
					endBucket=r['tmstp'].to_i
					c+=1
				end
			end
			if startBucket!=-1 && endBucket!=-1
				fw.puts "\n"+startBucket.to_s+" : "+endBucket.to_s+"-> BUCKET "+bucket.to_s
				fw.puts @trace.results_toString(@database,nil,nil)+"\n"
			end
			@trace=Trace.new(@defines)
			fr.close
			if fw!=nil
				fw.close
			end
		end
	end


	def applyTimeWindow(firstTime,row,fw)
		diff=row['tmstp'].to_i-firstTime
		wnum=diff.to_f/@window.to_i
		return wnum.to_i
	end	

	def reqOrigin(row)
		#CHECK IF ITS MOBILE USER
		mob,dev=@filters.is_MobileType?(row)   # check the device type of the request
		if mob==1
			@trace.mobDev+=1
		end
		#CHECK IF ITS ORIGINATED FROM BROWSER
		browser=@filters.is_Browser?(row)
		if browser!= "unknown"
			@trace.fromBrowser+=1
		end
        @trace.devs.push(dev)
		return mob,dev,browser
	end		

	def filterRow(row)
		url=row['url'].split("?")
		host=row['host']
		isPorI,noOfparam=beaconImprParamCkeck(url,row)
	#	@trace.totalParamNum.push(noOfparam)
		iaAdinURL=false
		@trace.sizes.push(row['dataSz'].to_i)
		type3rd=@filters.is_Ad?(url[0],host,@adFilter)
		if type3rd!=nil	#	3rd PARTY CONTENT
		#	@trace.users[@curUser].row3rdparty[type3rd].push(row)
			@trace.users[@curUser].size3rdparty[type3rd].push(row['dataSz'].to_i)
			@trace.users[@curUser].dur3rd[type3rd].push(row['dur'].to_i)
			@trace.party3rd[type3rd]+=1
			if not type3rd.eql? "Content"
				if	type3rd.eql? "Advertising"
					ad_detected(row,noOfparam,url)
				else # SOCIAL or ANALYTICS or OTHER type
					@trace.restNumOfParams.push(noOfparam.to_i)
				end
				#CALCULATE SIZE
				#@trace.users[@curUser].dur3rd[type3rd].push(row['dur'].to_i)
			else	#CONTENT type
				@trace.restNumOfParams.push(noOfparam.to_i)
		#		@trace.users[@curUser].restNumOfParams.push(noOfparam.to_i)
			end
		else
			if @isBeacon 	#Beacon NOT ad-related
				@trace.users[@curUser].size3rdparty["Beacons"].push(row['dataSz'].to_i)
				@trace.users[@curUser].dur3rd["Beacons"].push(row['dur'].to_i)
				@trace.restNumOfParams.push(noOfparam.to_i)
			elsif isPorI>0	# Impression or ad in param
				@trace.users[@curUser].size3rdparty["Advertising"].push(row['dataSz'].to_i)
				@trace.users[@curUser].dur3rd["Advertising"].push(row['dur'].to_i)
				ad_detected(row,noOfparam,url)
				@trace.party3rd["Advertising"]+=1
			elsif isPorI<1	# Rest
				@trace.restNumOfParams.push(noOfparam.to_i)
				@trace.users[@curUser].size3rdparty["Other"].push(row['dataSz'].to_i)
				@trace.users[@curUser].dur3rd["Other"].push(row['dur'].to_i)
				@trace.party3rd["Other"]+=1
				if (row['browser']!="unknown")
					@trace.users[@curUser].publishers.push(row)
				end
				#Utilities.printStrippedURL(url,@fl)	# dump leftovers
			end
		end
	end

	def perUserAnalysis
		puts "> Dumping to database..."
		durStats={"Advertising"=>{},"Beacons"=>{},"Social"=>{},"Analytics"=>{},"Content"=>{},"Other"=>{}}
		sizeStats={"Advertising"=>{},"Beacons"=>{},"Social"=>{},"Analytics"=>{},"Content"=>{},"Other"=>{}}
		for id,user in @trace.users do
			user.ads.each{|row| Utilities.printRowToDB(row,@database,@defines.tables['adsTable'],nil)}
			user.publishers.each{|row| tid=Digest::SHA256.hexdigest (row['tmstp']+"|"+row['url']); @database.insert(@defines.tables['publishersTable'], [tid,row['tmstp'],row['IPport'],row['uIP'],row['url'],row['host'],row['mob'],row['dev'],row['browser']])}
			user.size3rdparty.each{|category, sizes| sizeStats[category]=Utilities.makeStats(sizes)}
			user.dur3rd.each{|category, durations| durStats[category]=Utilities.makeStats(durations)}
			if @database!=nil
				avgDurPerCat="["+durStats['Advertising']['avg'].to_s+","+durStats['Analytics']['avg'].to_s+
				","+durStats['Social']['avg'].to_s+","+durStats['Content']['avg'].to_s+","+durStats['Beacons']['avg'].to_s+
				","+durStats['Other']['avg'].to_s+"]"
				sumSizePerCat="["+sizeStats['Advertising']['sum'].to_s+","+sizeStats['Analytics']['sum'].to_s+
				","+sizeStats['Social']['sum'].to_s+","+sizeStats['Content']['sum'].to_s+","+sizeStats['Beacons']['sum'].to_s+
				","+sizeStats['Other']['sum'].to_s+"]"

				@database.insert(@defines.tables['userTable'],[id,user.size3rdparty['Advertising'].size,user.size3rdparty['Analytics'].size,user.size3rdparty['Social'].size,user.size3rdparty['Content'].size,user.size3rdparty['Beacons'].size,user.size3rdparty['Other'].size,avgDurPerCat,sumSizePerCat,user.hashedPrices.length,user.numericPrices.length,user.adBeacon,user.imp.length,user.publishers.size])
			end
		end
	end

    def detectPrice(tmstp,keyVal,domainStr,url)          	# Detect possible price in parameters and returns URL Parameters in String
		domain,tld=Utilities.tokenizeHost(domainStr)
		host=domain+"."+tld
		if (@filters.is_inInria_PriceTagList?(host,keyVal) or @filters.has_PriceKeyword?(keyVal)) 		# Check for Keywords and if there aren't any make ad-hoc heuristic check
			priceTag=keyVal[0]
			priceVal=keyVal[1]
			if priceVal.include? "startapp" or priceVal.include? "pkg"
				return false
			end
			type=""
			if Utilities.is_float?(priceVal)
				@trace.users[@curUser].numericPrices.push(priceVal)
				@trace.numericPrices+=1
				type="numeric"
			else
				type="encrypted"
				if priceVal.size < 6
					return false
				end
				@trace.users[@curUser].hashedPrices.push(priceVal)
				@trace.hashedPrices+=1
			end
			if @database!=nil
				id=Digest::SHA256.hexdigest (tmstp+"|"+url+"|"+domainStr+"|"+priceTag+"|"+priceVal)
				@database.insert(@defines.tables['priceTable'], [id,tmstp,domainStr,priceTag.downcase,priceVal,type])
			end
			return true
		end
		return false
    end

    def detectImpressions(url,row)     	#Impression term in path
        if @filters.is_Impression?(url[0])
#			Utilities.printRowToDB(row,@database,@defines.tables['impTable'],nil)
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
				if(detectPrice(row['tmstp'],keyVal,row['host'],row['url']))
#					if row['browser']!=nil					
#						@trace.browserPrices+=1
#					end
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
		@trace.party3rd["totalBeacons"]+=1
		tmpstp=row['tmstp'];u=row['url']
		id=Digest::SHA256.hexdigest (tmpstp+"|"+u);
		@trace.beacons.push([id,tmpstp,row['IPport'],row['userIP'],u,type,row['mob'],row['dev'],row['browser']])
	end

	def beaconImprParamCkeck(url,row) 
        @isBeacon=false
		isAd=-1
        if (@filters.is_Beacon?(url[0]))  		#findBeacon in URL
            isAd=0
            beaconSave(url[0],row)
        end
        paramNum, result=checkParams(row,url)             #check in URL params
        if(result==true or detectImpressions(url,row))
            isAd=1
		end
		return isAd,paramNum
	end

	def ad_detected (row,noOfparam,url)
        @trace.users[@curUser].ads.push(row)
		@trace.adSize.push(row['dataSz'].to_i)
   #     @trace.users[@curUser].adNumOfParams.push(noOfparam.to_i)
		@trace.adNumOfParams.push(noOfparam.to_i)
		if (@isBeacon)			#is it ad-related Beacon?
			@trace.users[@curUser].adBeacon+=1
			@trace.totalAdBeacons+=1
			@isBeacon=false
		end
		if(row['mob'])
			@trace.numOfMobileAds+=1
		end
	end
end
