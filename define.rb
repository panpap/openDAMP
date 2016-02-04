class Defines
	attr_accessor :tables, :groupDir, :plotScripts, :plotDir, :resultsDB, :traceFile, :adsDir, :beaconDB, :filterFile, :parseResults, :userDir, :dirs, :files, :dataDir, :tmln_path
	
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
		traceName=""
		if @traceFile.include? "/" 
			s=@traceFile.split("/")
			traceName=s[s.size-2]+"_"+s.last
		else
			traceName=@traceFile
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
		if not File.exist?(@traceFile) and not File.exist?(@dirs["rootDir"])
			Utilities.error("Input file <"+filename.to_s+"> could not be found!")
		end

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
			"linespoints"=>@plotScriptsDir+"plotLinesPoints.gn",
			"stacked_area"=>@plotScriptsDir+"plotStacked_area.gn"}
	end

	def column_Format()
		return @column_Format[@traceFile]
	end
end
