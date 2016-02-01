class Defines
	attr_accessor :tables, :plotScripts, :plotDir, :resultsDB, :traceFile, :adsDir, :beaconDB, :filterFile, :parseResults, :userDir, :dirs, :files, :dataDir, :tmln_path
	
	def initialize(filename)
		@column_Format={"2monthSorted_trace"=>1,"10k_trace"=>1 ,
			"full_trace"=>1, 	#awazza dataset 6million reqs
			"souneil_trace"=>2,"souneilSorted_trace"=>2} 	#awazza dataset 1million reqs

		if filename==nil
			puts "Warning: Using pre-defined input file..."
			@traceFile="full_trace"
		else
			@traceFile=filename
		end
		if not File.exist?(@traceFile)
			abort("Error: Input file <"+filename.to_s+"> could not be found!")
		end

		@tables={
			"publishersTable"=>"publishers",
			"beaconDBTable"=>"beaconURLs",
			"impTable"=>"impressions",	
			"bcnTable"=>"beacons",
			"adsTable"=>"advertisements",
			"userTable"=>"userResults",
			"priceTable"=>"prices",
			"traceTable"=>"traceResults"}

		@beaconDB="beaconsDB.db"
		@resultsDB=@traceFile+"_analysis.db"

		#DIRECTORIES
		@dataDir="dataset/"
		@adsDir="adRelated/"
		@userDir="users/"
		@plotDir="plots/"
		@tmln_path="timelines/"
		
		@dirs=Hash.new	
		@dirs["rootDir"]="results_"+@traceFile+"/"
		@dirs["dataDir"]=@dirs["rootDir"]+@dataDir
		@dirs["adsDir"]=@dirs["rootDir"]+@adsDir
		@dirs["userDir"]=@dirs["rootDir"]+@userDir
		@dirs["timelines"]=@dirs["userDir"]+@tmln_path
		@dirs["plotDir"]=nil
		@resources="resources/"

		#FILENAMES
		@files={
		#@files["parseResults"=>@dirs["rootDir"]+"results.out",
			"priceTagsFile"=>@dirs["adsDir"]+"priceTags",
			"devices"=>@dirs["adsDir"]+"devices.csv",
			"size3rdFile"=>@dirs["adsDir"]+"sizes3rd.csv",
			"adParamsNum"=>@dirs["adsDir"]+"adParamsNum.csv",
			"restParamsNum"=>@dirs["adsDir"]+"restParamsNum.csv",
		#@files["adDevices"=>@dirs["adsDir"]+"adDevices.csv",
		#@files["userFile"=>@dirs["userDir"]+"userAnalysis.csv",
		#@files["publishers"=>@dirs["adsDir"]+"publishers.csv",
		#@files["leftovers"=>"leftovers.out",
			"formatFile"=>"format.in",
			"configFile"=>"config",
			"filterFile"=>@resources+"disconnect_merged.json"}

		#GNUPLOT SCRIPTS
		@plotScriptsDir="plotScripts/"
		@plotScripts={
			"cdf"=>@plotScriptsDir+"plotCDF.gn",
			"bars"=>@plotScriptsDir+"plotBars.gn",
			"zoomed"=>@plotScriptsDir+"plotZoomed.gn",
			"linespoints"=>@plotScriptsDir+"plotLinesPoints.gn"}
	end

	def column_Format()
		return @column_Format[@traceFile]
	end
end
