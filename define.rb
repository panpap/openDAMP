class Defines
	attr_accessor :tables, :plotDir, :resultsDB, :traceFile, :adsDir, :beaconDB, :filterFile, :parseResults, :userDir, :dirs, :files, :dataDir, :tmln_path
	
	def initialize(filename)
		@column_Format={'2m_trace'=>1,'10k_trace'=>1 ,
			'full_trace'=>1, 	#awazza dataset 6million reqs
			'souneil_trace'=>2} 	#awazza dataset 1million reqs

		if filename==nil
			puts "Warning: Using pre-defined input file..."
			@traceFile='full_trace'
		else
			@traceFile=filename
		end
		if not File.exist?(@traceFile)
			abort("Error: Input file <"+filename.to_s+"> could not be found!")
		end

		@tables=Hash.new
		@tables['publishersTable']="publishers"
		@tables['beaconDBTable']="beaconURLs"
		@tables['impTable']="impressions"		
		@tables['bcnTable']="beacons"
		@tables['adsTable']="advertisements"
		@tables['userTable']="userResults"
		@tables['priceTable']="prices"
		@tables['traceTable']="traceResults"

		@beaconDB="beaconsDB.db"
		@resultsDB=@traceFile+"_analysis.db"

		#DIRECTORIES
		@dirs=Hash.new
		@dataDir="dataset/"
		@adsDir="adRelated/"
		@userDir="users/"
		@plotDir="plots/"
		@tmln_path="timelines/"
		@dirs['rootDir']="results_"+@traceFile+"/"
		@dirs['dataDir']=@dirs['rootDir']+@dataDir
		@dirs['adsDir']=@dirs['rootDir']+@adsDir
		@dirs['userDir']=@dirs['rootDir']+@userDir
		@dirs['timelines']=@dirs['userDir']+@tmln_path
		@dirs['plotDir']=nil
		@resources='resources/'

		#FILENAMES
		@files=Hash.new
		#@files['parseResults']=@dirs['rootDir']+"results.out"
		@files['priceTagsFile']=@dirs['adsDir']+"priceTags"
		@files['devices']=@dirs['adsDir']+"devices.csv"
		@files['size3rdFile']=@dirs['adsDir']+"sizes3rd.csv"
		@files['adParamsNum']=@dirs['adsDir']+"adParamsNum.csv"
		@files['restParamsNum']=@dirs['adsDir']+"restParamsNum.csv"
		#@files['adDevices']=@dirs['adsDir']+"adDevices.csv"
		#@files['userFile']=@dirs['userDir']+"userAnalysis.csv"
		#@files['publishers']=@dirs['adsDir']+"publishers.csv"
	#	@files['leftovers']="leftovers.out"
		@files['formatFile']="format.in"
		@filterFile=@resources+'disconnect_merged.json'
	end

	def column_Format()
		return @column_Format[@traceFile]
	end
end
