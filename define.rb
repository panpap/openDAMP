require 'json'
load 'database.rb'

class Defines
	attr_accessor :tables, :siteFile, :beaconDBTable, :options, :groupDir, :plotScripts, :plotDir, :resultsDB, :traceFile, 
					:adsDir, :beaconDB, :userDir, :dirs, :files, :dataDir, :tmln_path, :resourceFiles

	def initialize(filename)
		@beaconDBTable="beaconURLs"
		@beaconDB="beaconsDB.db"
		@column_Format={"2monthSorted_trace"=>1,"10k_trace"=>1 ,
			"2m_trace"=>1, 	#awazza dataset 6million reqs
			"souneil_trace"=>2,"souneilSorted_trace"=>2} 	#awazza dataset 1million reqs
		filenames=["devices.csv","sizes3rd.csv","adParamsNum.csv","restParamsNum.csv","cmIDcount.csv","cmHosts.csv"]
		@traceFile=filename
		traceName=""
		@siteFile="./sites.csv"
		@resources="resources/"
		@resourceFiles={"filterFile"=>@resources+"disconnect_merged.json","interestsFile"=>@resources+"interests.csv",
					"geoCity"=>@resources+"GeoLite2-City.mmdb","geoCountry"=>@resources+"GeoLite2-Country.mmdb",
				}

		if @traceFile!=nil and File.exist?(@traceFile)
			if @traceFile.include? "/" 
				s=@traceFile.split("/")
				traceName=s[s.size-2]+"_"+s.last
			else
				traceName=@traceFile
			end	
			puts "InputFile: "+traceName
		# DATABASE
			@resultsDB=traceName+"_analysis.db"
			#DIRECTORIES
			@dataDir="dataset/"
			@adsDir="adRelated/"
			@userDir="users/"
			@plotDir="plots/"
			@tmln_path="timelines/"
		
			@dirs=Hash.new	
			@groupDir="grouppedRes/"
			if @traceFile.include? "/"
				Dir.mkdir groupDir unless File.exists?(groupDir)
				@dirs["rootDir"]=groupDir+"results_"+traceName+"/"
			else
				@dirs["rootDir"]="results_"+traceName+"/"
			end
			@dirs["dataDir"]=@dirs["rootDir"]+@dataDir
			@dirs["adsDir"]=@dirs["rootDir"]+@adsDir
			@dirs["userDir"]=@dirs["rootDir"]+@userDir
			@dirs["timelines"]=@dirs["userDir"]+@tmln_path
			@dirs["plotDir"]=nil
			#Utilities.error "Input file <"+filename.to_s+"> could not be found!"

			#FILENAMES
			@files={
				"devices"=>@dirs["adsDir"]+filenames[0],
				"size3rdFile"=>@dirs["adsDir"]+filenames[1],
				"adParamsNum"=>@dirs["adsDir"]+filenames[2],
				"restParamsNum"=>@dirs["adsDir"]+filenames[3],
				"cmIDcount"=>@dirs["adsDir"]+filenames[4],
				"cmHost"=>@dirs["adsDir"]+filenames[5]}
		
			#GNUPLOT SCRIPTS
			@plotScriptsDir="plotScripts/"
			@plotScripts={
				"cdf"=>@plotScriptsDir+"plotCDF.gn",
				"bars"=>@plotScriptsDir+"plotBars.gn",
				"zoomed"=>@plotScriptsDir+"plotZoomed.gn",
				"linespoints"=>@plotScriptsDir+"plotLinesPoints.gn",
				"stacked_area"=>@plotScriptsDir+"plotStacked_area.gn"}		
		else
			Utilities.warning "Cannot find "+@traceFile if @traceFile!=nil 
		end
		
		#DATABASES
		@tables={"publishersTable"=>{"publishers"=>'timestamp BIGINT, IP_Port VARCHAR, url VARCHAR , Host VARCHAR, mobile VARCHAR, device INTEGER, browser INTEGER,id VARCHAR PRIMARY KEY'},
			"impTable"=>{"impressions"=>'id VARCHAR PRIMARY KEY,timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR, url VARCHAR, Host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER'},
			"bcnTable"=>{"beacons"=>'timestamp BIGINT, ip_port VARCHAR, url VARCHAR, beaconType VARCHAR, mob INTEGER,device VARCHAR,browser VARCHAR, id VARCHAR PRIMARY KEY'},
			"advertiserTable"=>{"advertisers"=>'host VARCHAR PRIMARY KEY, numOfReqs BIGINT, numOfUsers BIGINT, avgReqPerUser INTEGER, avgDurOfReqs VARCHAR, totalDurOfReqs VARCHAR, avgSizeOfReqs VARCHAR,totalBytesDelivered BIGINT, type VARCHAR'},
			"adsTable"=>{"advertisements"=>'timestamp BIGINT, receiverType VARCHAR,ip_Port VARCHAR, url VARCHAR, dataSize INTEGER, duration INTEGER,mob INTEGER,device VARCHAR,browser VARCHAR, id VARCHAR PRIMARY KEY'},
			"userTable"=>{"userResults"=>'id VARCHAR PRIMARY KEY, totalRows BIGINT, advertising INTEGER, analytics INTEGER, social INTEGER, third_party_content INTEGER, beacons INTEGER, other INTEGER, avgDurationPerCategory VARCHAR, totalSizePerCategory VARCHAR, totalBytes BIGINT, avgBytesPerReq  VARCHAR, sumDuration BIGINT, avgDurationOfReq VARCHAR,  hashedPrices INTEGER, numericPrices INTEGER, impressions INTEGER, publishersVisited INTEGER, numOfCookieSyncs INTEGER, numOfLocations INTEGER, uniqLocations VARCHAR'},
			"userFilesTable"=>{"userFiletypes"=>'id VARCHAR PRIMARY KEY, Reqs_Advertising_data INTEGER, Reqs_Advertising_gif INTEGER, Reqs_Advertising_html INTEGER, Reqs_Advertising_image INTEGER, Reqs_Advertising_other INTEGER, Reqs_Advertising_script INTEGER, Reqs_Advertising_styling INTEGER, Reqs_Advertising_text INTEGER, Reqs_Advertising_video INTEGER, Reqs_Analytics_data INTEGER, Reqs_Analytics_gif INTEGER, Reqs_Analytics_html INTEGER, Reqs_Analytics_image INTEGER, Reqs_Analytics_other INTEGER, Reqs_Analytics_script INTEGER, Reqs_Analytics_styling INTEGER, Reqs_Analytics_text INTEGER, Reqs_Analytics_video INTEGER, Reqs_Social_data INTEGER, Reqs_Social_gif INTEGER, Reqs_Social_html INTEGER, Reqs_Social_image INTEGER, Reqs_Social_other INTEGER, Reqs_Social_script INTEGER, Reqs_Social_styling INTEGER, Reqs_Social_text INTEGER, Reqs_Social_video INTEGER, Reqs3rd_party_Content_data INTEGER, Reqs3rd_party_Content_gif INTEGER, Reqs3rd_party_Content_html INTEGER, Reqs3rd_party_Content_image INTEGER, Reqs3rd_party_Content_other INTEGER, Reqs3rd_party_Content_script INTEGER, Reqs3rd_party_Content_styling INTEGER, Reqs3rd_party_Content_text INTEGER, Reqs3rd_party_Content_video INTEGER, Reqs_Beacons_data INTEGER, Reqs_Beacons_gif INTEGER, Reqs_Beacons_html INTEGER, Reqs_Beacons_image INTEGER, Reqs_Beacons_other INTEGER, Reqs_Beacons_script INTEGER, Reqs_Beacons_styling INTEGER, Reqs_Beacons_text INTEGER, Reqs_Beacons_video INTEGER, Reqs_Other_data INTEGER, Reqs_Other_gif INTEGER, Reqs_Other_html INTEGER, Reqs_Other_image INTEGER, Reqs_Other_other INTEGER, Reqs_Other_script INTEGER, Reqs_Other_styling INTEGER, Reqs_Other_text INTEGER, Reqs_Other_video INTEGER, TotalBytes_Advertising_data INTEGER, TotalBytes_Advertising_gif INTEGER, TotalBytes_Advertising_html INTEGER, TotalBytes_Advertising_image INTEGER, TotalBytes_Advertising_other INTEGER, TotalBytes_Advertising_script INTEGER, TotalBytes_Advertising_styling INTEGER, TotalBytes_Advertising_text INTEGER, TotalBytes_Advertising_video INTEGER, TotalBytes_Analytics_data INTEGER, TotalBytes_Analytics_gif INTEGER, TotalBytes_Analytics_html INTEGER, TotalBytes_Analytics_image INTEGER, TotalBytes_Analytics_other INTEGER, TotalBytes_Analytics_script INTEGER, TotalBytes_Analytics_styling INTEGER, TotalBytes_Analytics_text INTEGER, TotalBytes_Analytics_video INTEGER, TotalBytes_Social_data INTEGER, TotalBytes_Social_gif INTEGER, TotalBytes_Social_html INTEGER, TotalBytes_Social_image INTEGER, TotalBytes_Social_other INTEGER, TotalBytes_Social_script INTEGER, TotalBytes_Social_styling INTEGER, TotalBytes_Social_text INTEGER, TotalBytes_Social_video INTEGER, TotalBytes3rd_party_Content_data INTEGER, TotalBytes3rd_party_Content_gif INTEGER, TotalBytes3rd_party_Content_html INTEGER, TotalBytes3rd_party_Content_image INTEGER, TotalBytes3rd_party_Content_other INTEGER, TotalBytes3rd_party_Content_script INTEGER, TotalBytes3rd_party_Content_styling INTEGER, TotalBytes3rd_party_Content_text INTEGER, TotalBytes3rd_party_Content_video INTEGER, TotalBytes_Beacons_data INTEGER, TotalBytes_Beacons_gif INTEGER, TotalBytes_Beacons_html INTEGER, TotalBytes_Beacons_image INTEGER, TotalBytes_Beacons_other INTEGER, TotalBytes_Beacons_script INTEGER, TotalBytes_Beacons_styling INTEGER, TotalBytes_Beacons_text INTEGER, TotalBytes_Beacons_video INTEGER, TotalBytes_Other_data INTEGER, TotalBytes_Other_gif INTEGER, TotalBytes_Other_html INTEGER, TotalBytes_Other_image INTEGER, TotalBytes_Other_other INTEGER, TotalBytes_Other_script INTEGER, TotalBytes_Other_styling INTEGER, TotalBytes_Other_text INTEGER, TotalBytes_Other_video INTEGER'},
			"priceTable"=>{"prices"=> 'type VARCHAR, timestamp BIGINT, host VARCHAR, priceTag VARCHAR, priceValue VARCHAR, bytes INTEGER, upToKnowCM INTEGER, numOfParams INTEGER, adSize	VARCHAR, adPosition VARCHAR, userLocation VARCHAR, TOD VARCHAR, interest VARCHAR, pubPopularity INTEGER, userId VARCHAR, associatedSSP VARCHAR, associatedDSP VARCHAR, associatedADX VARCHAR, mob VARCHAR, device VARCHAR, browser VARCHAR, url VARCHAR, id VARCHAR PRIMARY KEY'},
			"traceTable"=>{"traceResults"=>'totalRows BIGINT, users INTEGER, advertising INTEGER, analytics INTEGER, social INTEGER, third_party_content INTEGER, beacons INTEGER, other INTEGER, thirdPartySize_total INTEGER, totalMobileReqs INTEGER, browserReqs INTEGER,mobileAdReqs VARCHAR, hashedPrices INTEGER, numericPrices INTEGER, numImpressions INTEGER,id VARCHAR PRIMARY KEY'},
			"csyncTable"=>{"csyncResults"=>'prevTimestamp BIGINT,curTimestamp BIGINT,hostPrev VARCHAR,prevCat VARCHAR, hostCur VARCHAR,curCat VARCHAR, paramNamePrev VARCHAR, userID VARCHAR, paramNameCur VARCHAR, prevStatus INTEGER, curStatus INTEGER, possibleNumberOfIDs INTEGER,confirmed INTEGER, allParamsPrev VARCHAR, allParamsCur VARCHAR, id VARCHAR PRIMARY KEY'},
			"visitsTable"=>{"userVisits"=> 'userID VARCHAR PRIMARY KEY, totalVisits INTEGER,visits VARCHAR, interests VARCHAR'}
		}

		#LOAD OPTIONS
		configFile="config"
		@options,str=Utilities.loadOptions(configFile,filenames,@tables)
		
		#OUTPUT
		if @options["printToSTDOUT?"]
			@fw=STDOUT
		else
			@fw=nil
		end
		puts str
	end

	def puts(str)
		print str+"\n"
	end

	def print (str)
		if @fw!=nil
			@fw.print str
		end
	end

	def close
		@fw.close
	end

	def column_Format()
		return @column_Format[@traceFile]
	end
end
