load 'user.rb'


class Trace
	attr_accessor :adSize, :cooksyncs,:fromBrowser, :beacons, :party3rd,:restNumOfParams, :adNumOfParams, :devs, :numericPrices, :mobDev, 
				:numOfMobileAds, :totalImps, :users, :hashedPrices, :sizes, :totalParamNum

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
		@numOfMobileAds=0
		@beacons=Array.new
		@adNumOfParams=Array.new
		@restNumOfParams=Array.new
		@totalImps=0
		@cooksyncs=0;
		@adSize=Array.new
		@party3rd={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0, "Other"=>0, "Beacons"=>0}
	end

	def analyzeTotalAds    #Analyze global variables
		Utilities.countInstances(@defines.files['adParamsNum'])
		Utilities.countInstances(@defines.files['restParamsNum'])
		Utilities.countInstances(@defines.files['devices'])
		Utilities.countInstances(@defines.files['size3rdFile'])
		#return Utilities.makeStats(@totalParamNum),Utilities.makeStats(@adNumOfParams),Utilities.makeStats(@restNumOfParams),Utilities.makeStats(@sizes)
		return Utilities.makeStats(@sizes)
	end

	def results_toString(db,traceTable,beaconTable,cats)
		totalNumofRows=(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+@party3rd['Beacons']+@party3rd['Content']+@party3rd['Other'])
		sizeStats=analyzeTotalAds
		#PRINTING RESULTS
		if traceTable!=nil
			s="> Printing Results...\n\n------------\nTRACE STATS\n"+"- Total users in trace: "+@users.size.to_s+
			"\n- Total Number of rows = "+totalNumofRows.to_s+"\n- Traffic from  mobile devices: "+
			@mobDev.to_s+"/"+totalNumofRows.to_s+"\n"+"- Traffic originated from Web Browser: "+@fromBrowser.to_s+
			"\n- 3rd Party reqs detected: \n\tAdvertising => "+@party3rd['Advertising'].to_s+
			"\n\tAnalytics => "+@party3rd['Analytics'].to_s+"\n\tSocial => "+@party3rd['Social'].to_s+"\n\t3rd_party_Content => "+@party3rd['Content'].to_s+
			"\n\tBeacons => "+@party3rd['Beacons'].to_s+"\n\tOther => "+@party3rd['Other'].to_s+
			"\n- Total Size: "+sizeStats['sum'].to_s+" Bytes\n\tAverage per req: "+
			sizeStats['avg'].to_s+" Bytes"+"\n\nADVERTISING STATS\n- AdRelated traffic from mobile devices: "+@numOfMobileAds.to_s+"/"+
			@party3rd['Advertising'].to_s+"\n- Prices Detected "+(@numericPrices+@hashedPrices).to_s+"\n\tHashed Price tags found: "+@hashedPrices.to_s+
			"\n\tNumeric Price tags found: "+@numericPrices.to_s+"\n- Advertising reqs Total size "+(Utilities.makeStats(@adSize)["sum"]).to_s+
			"\n- Cookie Synchronizations detected: "+cooksyncs.to_s+
			"\n------------\n"#-Impressions detected "+@totalImps.to_s+"\n"


			if db!=nil
				@beacons.each{|array| db.insert(beaconTable,array)}			
				params=[totalNumofRows,@users.size,@party3rd['Advertising'],@party3rd['Analytics'],@party3rd['Social'],
				@party3rd['Content'],@party3rd['Beacons'],@party3rd['Other'],sizeStats['sum'],@mobDev,@fromBrowser.size,@numOfMobileAds.to_s+"/"+
				@party3rd['Advertising'].to_s,@hashedPrices,@numericPrices,	@totalImps]	
				id=Digest::SHA256.hexdigest (params.join("|"))	
				db.insert(traceTable,params.push(id))
			end
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
			@party3rd['Advertising'].to_s+";"+@hashedPrices.to_s+";"+@numericPrices.to_s+
			";"+@party3rd['Beacons'].to_s+
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

	def dumpUserRes(db,durStats,sizeStats,filters,allowOptions)
		cats=filters.getCats
		options=@defines.options['resultToFiles']
		for id,user in users do
			#ADVERTISEMENTS
			if user.ads!=nil and allowOptions[@defines.tables["adsTable"].keys[0]]
				user.ads.each{|row|		
					receiverType=filters.getReceiverType(row['host'])
					params=[row['tmstp'],receiverType,row['IPport'],row['url'],row['dataSz'],row['dur'],row['mob'],row['dev'],row['browser']]
					aid=Digest::SHA256.hexdigest (params.join("|"));
					db.insert(@defines.tables['adsTable'], params.push(aid))}
			end
			#COOKIE SYNC
			if user.csync!=nil and allowOptions[@defines.tables["csyncTable"].keys[0]]				
				user.csync.each{|elem| db.insert(@defines.tables['csyncTable'], elem)}
				if options[@defines.files['cmIDcount'].split("/").last] and not File.size?@defines.files['cmIDcount']
					fw=File.new(@defines.files["cmIDcount"],"w")
					user.csyncIDs.each{|cookieID, count| fw.puts count.to_s+"\t"+cookieID+"\t"+id.to_s}
					fw.close
				end
				if options[@defines.files['cmHost'].split("/").last] and not File.size?@defines.files['cmHost']
					fw=File.new(@defines.files["cmHost"],"w")
					user.csyncHosts.each{|hosts, array| fw.puts id.to_s+"\t"+hosts+"\t"+array.size.to_s+"\t"+array.to_s}
					fw.close
				end
			end
			#PUBLISHERS
			if user.publishers!=nil and allowOptions[@defines.tables["publishersTable"].keys[0]]
				user.publishers.each{|row| 
					tid=Digest::SHA256.hexdigest (row.values.join("|")); 
					db.insert(@defines.tables['publishersTable'], [row['tmstp'],row['IPport'],row['url'],row['host'],row['mob'],row['dev'],row['browser'],tid])}
			end
			#3rd PARTY
			if user.size3rdparty!=nil and sizeStats!=nil
				user.size3rdparty.each{|category, sizes| sizeStats[category]=Utilities.makeStats(sizes)}
			end
			if user.dur3rd!=nil and durStats!=nil
				user.dur3rd.each{|category, durations| durStats[category]=Utilities.makeStats(durations)}
			end
			if durStats!=nil and sizeStats!=nil 
				totalRows=user.size3rdparty['Advertising'].size+user.size3rdparty['Analytics'].size+user.size3rdparty['Social'].size+user.size3rdparty['Content'].size+user.size3rdparty['Beacons'].size+user.size3rdparty['Other'].size
				avgDurPerCat="["+durStats['Advertising']['avg'].to_s+","+durStats['Analytics']['avg'].to_s+
				","+durStats['Social']['avg'].to_s+","+durStats['Content']['avg'].to_s+","+durStats['Beacons']['avg'].to_s+
				","+durStats['Other']['avg'].to_s+"]"
				sumSizePerCat="["+sizeStats['Advertising']['sum'].to_s+","+sizeStats['Analytics']['sum'].to_s+
				","+sizeStats['Social']['sum'].to_s+","+sizeStats['Content']['sum'].to_s+","+sizeStats['Beacons']['sum'].to_s+
				","+sizeStats['Other']['sum'].to_s+"]"
				if db!=nil and allowOptions[@defines.tables["userTable"].keys[0]]
					fileTypesArray=Utilities.printFileTypeAnalysis(cats,user).split("\t")
					params=[id,totalRows,user.size3rdparty['Advertising'].size,user.size3rdparty['Analytics'].size,user.size3rdparty['Social'].size,user.size3rdparty['Content'].size,user.size3rdparty['Beacons'].size,user.size3rdparty['Other'].size,avgDurPerCat,sumSizePerCat,user.hashedPrices.length,user.numericPrices.length,user.imp.length,user.publishers.size]
					db.insert(@defines.tables['userTable'],params+fileTypesArray)
				end
				if users.size==1
					@defines.puts "> Dumping results to <"+@defines.siteFile+"> for the individual website..."
					Utilities.individualSites(@defines.siteFile,@defines.traceFile,user,sumSizePerCat,avgDurPerCat,cats)
				end
			end					
		end
	end
end

