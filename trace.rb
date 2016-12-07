load 'entities.rb'

class Trace
	attr_accessor :adSize, :paramDups, :cooksyncs, :fromBrowser, :beacons, :party3rd,:restNumOfParams, :adNumOfParams, :devs, :numericPrices, :mobDev, 
				 :totalImps, :users, :hashedPrices, :sizes, :totalParamNum, :advertisers

	def initialize(defs)
		@defines=defs
		@mobDev=0
		@users=Hash.new
		#@totalParamNum=Array.new
		@hashedPrices=0
		@sizes=Array.new
		@devs=Array.new
		@fromBrowser=0
		@numericPrices=0
		@advertisers=Hash.new(nil)
		@beacons=Array.new
		@adNumOfParams=Array.new
		@restNumOfParams=Array.new
		@totalImps=0
		@paramDups=Hash.new
		@cooksyncs=0;
		@adSize=Array.new
		@party3rd={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0, "Other"=>0, "Beacons"=>0}
	end

	def results_toString(mode,db,traceTable)
		totalNumofRows=(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+@party3rd['Content']+@party3rd['Other'])#+@party3rd['Beacons']
		sizeStats=analyzeTotalAds()
		whatAmI=""
		case mode
		when 0 
			whatAmI="OVERALL"
		when 1 
			whatAmI="WEB"
		when 2 
			whatAmI="APP"
		else 
			Utilities.error "WRONG INPUT"
		end
		#PRINTING RESULTS
		if traceTable!=nil
			s="> Printing Results...\n\n------------\n"+whatAmI+" TRACE STATS\n"+"- Total users in trace: "+@users.size.to_s+
			"\n- Total Number of rows = "+totalNumofRows.to_s+"\n- Traffic from  mobile devices: "+
			@mobDev.to_s+"/"+totalNumofRows.to_s+"\n"+"- Traffic originated from Web Browser: "+@fromBrowser.to_s+
			"\n- 3rd Party reqs detected: \n\tAdvertising => "+@party3rd['Advertising'].to_s+
			"\n\tAnalytics => "+@party3rd['Analytics'].to_s+"\n\tSocial => "+@party3rd['Social'].to_s+"\n\t3rd_party_Content => "+@party3rd['Content'].to_s+
			"\n\tBeacons => "+@party3rd['Beacons'].to_s+"\n\tOther => "+@party3rd['Other'].to_s+
			"\n- Total Size: "+sizeStats['sum'].to_i.to_s+" Bytes\n\tAverage per req: "+
			sizeStats['avg'].to_s+" Bytes"+"\n\nADVERTISING STATS"+"\n- Advertising reqs Total size: "+(Utilities.makeStats(@adSize)["sum"]).to_s+"\n"
			if @defines.options['tablesDB'][@defines.tables["priceTable"].keys[0]]
				s+="- Prices Detected "+(@numericPrices+@hashedPrices).to_s+"\n\tHashed Price tags found: "+@hashedPrices.to_s+
						"\n\tNumeric Price tags found: "+@numericPrices.to_s+"\n"
			end
			if @defines.options['tablesDB'][@defines.tables["csyncTable"].keys[0]]
				s+="- Cookie Synchronizations detected: "+cooksyncs.to_s+"\n- Unique Advertisers: "+@advertisers.size.to_s+"\n"
			end
			s+="------------\n"#-Impressions detected "+@totalImps.to_s+"\n"
		#	printDuplicates()
			return s
		else
			header="Total users in trace;Traffic from mobile devices;Traffic originated from Browser;Browser-prices;"+
			"3rd Party reqs detected: [Advertising,Analytics,Social,3rd_party_Content,Beacons,Other];"+
			"3rd Party reqs size: [Total,Average];Total Number of rows;Ad-related traffic using mobile devices;"+
			"hashed prices;numeric prices;Beacons found;Impressions detected;noOfPublishers;Publishers;\n"
			s=@users.size.to_s+";"+
			@mobDev.to_+";"+@fromBrowser.to_s+";["+@party3rd['Advertising'].to_s+
			","+@party3rd['Analytics'].to_s+","+@party3rd['Social'].to_s+","+@party3rd['Content'].to_s+
			","+@party3rd['Beacons'].to_s+","+@party3rd['Other'].to_s+"];["+sizeStats['sum'].to_s+","+
			sizeStats['avg'].to_s+"];"+(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+
			@party3rd['Beacons']+@party3rd['Content']+@party3rd['Other']-@totalAdBeacons).to_s+";"+@numOfMobileAds.to_s+"/"+
			@party3rd['Advertising'].to_s+";"+@hashedPrices.to_s+";"+@numericPrices.to_s+";"+@party3rd['Beacons'].to_s+
			";"+@totalImps.to_s+";"+@publishers.size.to_s+"\n"
			if @publishers.size>0 
				str="["
				@publishers.each{ |pubs| str=str+" | "+pubs}
				return header+s+str+"]\n"
			else
				return header+s+"\n"
			end
		end
	end

	def dumpUserRes(db,filters,conv,csyncOnly,mode)
		durStats=nil;sizeStats=nil;userFilesTable=nil;userTable=nil;
		if not csyncOnly
			durStats={"Advertising"=>{},"Beacons"=>{},"Social"=>{},"Analytics"=>{},"Content"=>{},"Other"=>{}}
			sizeStats={"Advertising"=>{},"Beacons"=>{},"Social"=>{},"Analytics"=>{},"Content"=>{},"Other"=>{}}
		end
		case mode
		when 0
			userFilesTable=@defines.tables["userFilesTable"]
			userTable=@defines.tables["userTable"]
		when 1
			userFilesTable=@defines.tables["webUserFilesTable"]
			userTable=@defines.tables["webUserTable"]
		when 2
			userFilesTable=@defines.tables["appUserFilesTable"]
			userTable=@defines.tables["appUserTable"]
		else
			Utilities.error "Wrong input!"
		end
puts userTable.keys.first+" "+userFilesTable.keys.first
		start = Time.now
		cats=filters.getCats
		allowOptions=@defines.options['tablesDB']
		options=@defines.options['resultToFiles']
		count=0
		arr=Array.new
		if mode==0
			if options[@defines.files['cmIDcount'].split("/").last] and not File.size?@defines.files['cmIDcount']
				fcm1=File.new(@defines.files["cmIDcount"],"w")
				fcm1.puts "userID\tpair that shared the information (uni-directional)\t" 
			end
			if options[@defines.files['cmHost'].split("/").last] and not File.size?@defines.files['cmHost']
				fcm2=File.new(@defines.files["cmHost"],"w")
				fcm2.puts "appearances\tcookieID"
			end
		end
		for id,user in users do	
#puts count.to_s+" users were stored..."+(Time.now).to_i.to_s #if count%10==0
			#ADVERTISEMENTS
			if mode==0
				if user.ads!=nil and allowOptions[@defines.tables["adsTable"].keys[0]]
					user.ads.each{|row|		
						receiverType=filters.getReceiverType(row['host'])
						params=[row['tmstp'],receiverType,row['IPport'],row['url'],row['dataSz'],row['dur'],row['mob'],row['dev'].to_s,row['browser']]
						aid=Digest::SHA256.hexdigest (params.join("|"));
						db.insert(@defines.tables['adsTable'], params.push(aid))}
				end
				#COOKIE SYNC
				if user.csync!=nil and allowOptions[@defines.tables["csyncTable"].keys[0]]				
					user.csync.each{|elem| db.insert(@defines.tables['csyncTable'], elem)}
					user.csyncIDs.each{|cookieID, count| fcm1.puts count.to_s+"\t"+cookieID+"\t"+id.to_s} if fcm1!=nil
					user.csyncHosts.each{|hosts, array| fcm2.puts id.to_s+"\t"+hosts+"\t"+array.size.to_s+"\t"+array.to_s} if fcm2!=nil
				end
				#PUBLISHERS
				if user.publishers!=nil and allowOptions[@defines.tables["publishersTable"].keys[0]]
					user.publishers.each{|row| 
						tid=Digest::SHA256.hexdigest (row.values.join("|")); 
						db.insert(@defines.tables['publishersTable'], [row['tmstp'],row['IPport'],row['url'],row['host'],row['mob'],row['dev']["deviceBrand"],row['dev']["deviceModel"],row['dev']["osFamily"],row['dev']["osName"],row['dev']["uaType"],row['dev']["uaFamily"],row['dev']["uaName"],row['dev']["uaCategory"],row['browser'],tid])}
				end
			end
			#3rd PARTY
			arr[count] = Thread.new {
				user.size3rdparty.each{|category, sizes| sizeStats[category]=Utilities.makeStats(sizes)} if user.size3rdparty!=nil and sizeStats!=nil
				user.dur3rd.each{|category, durations| durStats[category]=Utilities.makeStats(durations)} if user.dur3rd!=nil and durStats!=nil
				if durStats!=nil and sizeStats!=nil
					totalRows=user.size3rdparty['Advertising'].size+user.size3rdparty['Analytics'].size+user.size3rdparty['Social'].size+user.size3rdparty['Content'].size+user.size3rdparty['Other'].size#+user.size3rdparty['Beacons'].size
					avgDurPerCat="["+durStats['Advertising']['avg'].to_s+","+durStats['Analytics']['avg'].to_s+","+durStats['Social']['avg'].to_s+
						","+durStats['Content']['avg'].to_s+","+durStats['Other']['avg'].to_s+"]"#+durStats['Beacons']['avg'].to_s
					sumSizePerCat="["+sizeStats['Advertising']['sum'].to_s+","+sizeStats['Analytics']['sum'].to_s+","+sizeStats['Social']['sum'].to_s+
						","+sizeStats['Content']['sum'].to_s+","+sizeStats['Other']['sum'].to_s+"]"#+sizeStats['Beacons']['sum'].to_s
					sumDurPerCat="["+durStats['Advertising']['sum'].to_s+","+durStats['Analytics']['sum'].to_s+","+durStats['Social']['sum'].to_s+
						","+durStats['Content']['sum'].to_s+","+durStats['Other']['sum'].to_s+"]"#+durStats['Beacons']['avg'].to_s
					if db!=nil or not @defines.options["database?"]
						if allowOptions[userTable.keys.first]
							totalBytes=(sizeStats['Advertising']['sum'].to_i+sizeStats['Analytics']['sum'].to_i+sizeStats['Social']['sum'].to_i+sizeStats['Content']['sum'].to_i+sizeStats['Other']['sum'].to_i)#+sizeStats['Beacons']['sum'].to_i
							sumDuration=(durStats['Advertising']['sum'].to_i+durStats['Analytics']['sum'].to_i+durStats['Social']['sum'].to_i+durStats['Content']['sum'].to_i+durStats['Other']['sum'].to_i)#+durStats['Beacons']['sum'].to_i
							avgBytesPerReq=Utilities.makeStats(user.size3rdparty['Advertising']+user.size3rdparty['Analytics']+user.size3rdparty['Social']+user.size3rdparty['Content']+user.size3rdparty['Other'])['avg']#+user.size3rdparty['Beacons']
							avgDurationOfReq=Utilities.makeStats(user.dur3rd['Advertising']+user.dur3rd['Analytics']+user.dur3rd['Social']+user.dur3rd['Content']+user.dur3rd['Other'])['avg']#+user.dur3rd['Beacons']
							locations=conv.getGeoLocation(user.uIPs.keys)
							params=[id, totalRows, user.size3rdparty['Advertising'].size, user.size3rdparty['Analytics'].size, user.size3rdparty['Social'].size, 
								user.size3rdparty['Content'].size, user.size3rdparty['Other'].size, avgDurPerCat, sumSizePerCat, 
								totalBytes,avgBytesPerReq, sumDuration, avgDurationOfReq, user.hashedPrices.length, user.numericPrices.length, user.imp.length, 
								user.publishers.size, user.size3rdparty['Beacons'].size,user.csync.size, locations.size, locations.to_s,sumDurPerCat]
							db.insert(userTable,params)
						end		
						if allowOptions[userFilesTable.keys.first]
							cats.delete("Beacons")
							fileTypesArray=Utilities.printFileTypeAnalysis(cats,user).split("\t")
							db.insert(userFilesTable,fileTypesArray.unshift(id))
						end
						if allowOptions[@defines.tables["visitsTable"].keys.first] and mode==0
							totalVisits=Utilities.makeStats(user.pubVisits.values)
							ints="nil"
							ints=Hash[user.interests.sort_by{|k,v| k}].to_s if user.interests!=nil
							db.insert(@defines.tables['visitsTable'],[id,totalVisits['sum'].to_i,user.pubVisits.to_s,ints])
						end
					end
					if users.size==1 and mode==0
						@defines.puts "> Dumping results to <"+@defines.siteFile+"> for the individual website..."
						cats.delete("Beacons")
						Utilities.individualSites(@defines.siteFile,@defines.traceFile,user,sumSizePerCat,avgDurPerCat,cats)
					end
			end
			count+=1
			}
			arr.each {|t| t.join}					
		end
		print "Total Dumping time for\t"
		print case mode
		when 0
			"overall userResults "
		when 1
			"web userResults "
		when 2
			"app userResults "
		end
		puts ((Time.now) - start).to_s+" seconds"
		fcm1.close if fcm1!=nil
		fcm2.close if fcm2!=nil
	end

	def dumpRes(db,traceTable,beaconTable,advertiserTable)
		if db!=nil and traceTable!=nil
			totalNumofRows=(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+@party3rd['Content']+@party3rd['Other'])#+@party3rd['Beacons']
			sizeStats=analyzeTotalAds()
			#beacons				
			@beacons.each{|array| db.insert(beaconTable,array)}	

			#traceresults		
			params=[totalNumofRows,@users.size,@party3rd['Advertising'],@party3rd['Analytics'],@party3rd['Social'],
				@party3rd['Content'],@party3rd['Beacons'],@party3rd['Other'],sizeStats['sum'],@mobDev,@fromBrowser,@hashedPrices,@numericPrices,@totalImps]	
			id=Digest::SHA256.hexdigest (params.join("|"))	
			db.insert(traceTable,params.push(id))

			#advertisers
			@advertisers.each{|host, attrs| 
				sizes=Utilities.makeStats(attrs.sizePerReq)
				durs=Utilities.makeStats(attrs.durPerReq)
				reqPerUser=Utilities.makeStats(attrs.reqsPerUser.values)
				totalReqs=reqPerUser['sum']
				params=[host, totalReqs, attrs.reqsPerUser.size, reqPerUser['avg'], durs['avg'], durs['sum'], sizes['avg'], sizes['sum'], attrs.type]
				db.insert(advertiserTable, params)
			}				
		end
	end

#--------------------------------------------------------------------------------

	private

	def printDuplicates
		return if not @defines.options["removeDuplicates?"]
		puts "printing Duplicates..."
		fw=File.new(@defines.dirs["rootDir"]+"duplicates.csv",'w')
		@paramDups.each{|key, value| fw.puts value['count'].to_s+"\t"+value['url'].to_s+"\t"+value['tmpstp'].to_s if value['count']>1}
		fw.close
	end

	def analyzeTotalAds()    #Analyze global variables
		Utilities.countInstances(@defines.files['adParamsNum'])
		Utilities.countInstances(@defines.files['restParamsNum'])
		Utilities.countInstances(@defines.files['devices'])
		Utilities.countInstances(@defines.files['size3rdFile'])
		#return Utilities.makeStats(@totalParamNum),Utilities.makeStats(@adNumOfParams),Utilities.makeStats(@restNumOfParams),Utilities.makeStats(@sizes)
		return Utilities.makeStats(@sizes)
	end
end
