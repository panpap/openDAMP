class Defines
	attr_accessor :tables, :beaconDBTable, :options, :groupDir, :plotScripts, :plotDir, :resultsDB, :traceFile, :adsDir, :beaconDB, :userDir, :dirs, :files, :dataDir, :tmln_path

	def initialize(filename)
		@beaconDBTable="beaconURLs"
		@column_Format={"2monthSorted_trace"=>1,"10k_trace"=>1 ,
			"full_trace"=>1, 	#awazza dataset 6million reqs
			"souneil_trace"=>2,"souneilSorted_trace"=>2} 	#awazza dataset 1million reqs
		filenames=["devices.csv","sizes3rd.csv","adParamsNum.csv","restParamsNum.csv"]
		if filename==nil
			puts "Warning: Using pre-defined input file..."
			@traceFile="full_trace"
		else
			@traceFile=filename
		end
		traceName=""
		if @traceFile.include? "/" 
			s=@traceFile.split("/")
			traceName=s[s.size-2]+"_"+s.last
		else
			traceName=@traceFile
		end	
	
		# DATABASE
		@beaconDB="beaconsDB.db"
		@tables={"publishersTable"=>{"publishers"=>'id VARCHAR PRIMARY KEY, timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR, url VARCHAR , Host VARCHAR, mobile VARCHAR, device INTEGER, browser INTEGER'},
				"impTable"=>{"impressions"=>'id VARCHAR PRIMARY KEY,timestamp BIGINT, IP_Port VARCHAR, UserIP VARCHAR, url VARCHAR, Host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER'},
				"bcnTable"=>{"beacons"=>'id VARCHAR PRIMARY KEY, timestamp BIGINT, ip_port VARCHAR, userIP VARCHAR, url VARCHAR, beaconType VARCHAR, mob INTEGER,device VARCHAR,browser VARCHAR'},
				"adsTable"=>{"advertisements"=>'id VARCHAR PRIMARY KEY, timestamp BIGINT, ip_Port VARCHAR, userIP VARCHAR, url VARCHAR, host VARCHAR, userAgent VARCHAR, status INTEGER, length INTEGER, dataSize INTEGER, duration INTEGER,mob INTEGER,device VARCHAR,browser VARCHAR'},
				"userTable"=>{"userResults"=>'id VARCHAR PRIMARY KEY, advertising INTEGER, analytics INTEGER, social INTEGER, content INTEGER, noAdBeacons INTEGER, other INTEGER, avgDurationPerCategory VARCHAR, totalSizePerCategory VARCHAR, hashedPrices INTEGER, numericPrices INTEGER,adBeacons INTEGER, impressions INTEGER, publishersVisited INTEGER'},
				"priceTable"=>{"prices"=>'id VARCHAR PRIMARY KEY,timestamp BIGINT, host VARCHAR, priceTag VARCHAR, priceValue VARCHAR,type VARCHAR, mob INTEGER, device VARCHAR, browser VARCHAR, url VARCHAR'},
				"traceTable"=>{"traceResults"=>'id VARCHAR PRIMARY KEY, totalRows BIGINT, users INTEGER, advertising INTEGER, analytics INTEGER, social INTEGER, content INTEGER, beacons INTEGER, other INTEGER, thirdPartySize_total INTEGER, totalMobileReqs INTEGER, browserReqs INTEGER,mobileAdReqs VARCHAR, hashedPrices INTEGER, numericPrices INTEGER, adRelatedBeacons VARCHAR, numImpressions INTEGER'},
				"csyncTable"=>{"csyncResults"=>'prevTimestamp BIGINT,curTimestamp BIGINT,hostPrev VARCHAR, hostCur VARCHAR, paramNamePrev VARCHAR, userID VARCHAR, paramNameCur VARCHAR, allParamsPrev VARCHAR, allParamsCur VARCHAR, id VARCHAR PRIMARY KEY'}
		}
	
		if File.exist?(@traceFile)
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
			@resources="resources/"
			#Utilities.error "Input file <"+filename.to_s+"> could not be found!"

		#FILENAMES
		@files={
			"devices"=>@dirs["adsDir"]+filenames[0],
			"size3rdFile"=>@dirs["adsDir"]+filenames[1],
			"adParamsNum"=>@dirs["adsDir"]+filenames[2],
			"restParamsNum"=>@dirs["adsDir"]+filenames[3],
			"formatFile"=>"format.in",
			"filterFile"=>@resources+"disconnect_merged.json"}
		
		#GNUPLOT SCRIPTS
		@plotScriptsDir="plotScripts/"
		@plotScripts={
			"cdf"=>@plotScriptsDir+"plotCDF.gn",
			"bars"=>@plotScriptsDir+"plotBars.gn",
			"zoomed"=>@plotScriptsDir+"plotZoomed.gn",
			"linespoints"=>@plotScriptsDir+"plotLinesPoints.gn",
			"stacked_area"=>@plotScriptsDir+"plotStacked_area.gn"}		
		end
		
		#LOAD OPTIONS
		configFile="config"
		@options,str=Utilities.loadOptions(configFile,filenames,@tables)
		
		#OUTPUT
		if @options["printToSTDOUT"]
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
