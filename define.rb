class Defines
	attr_accessor :tables, :plotDir, :resultsDB, :traceFile, :adsDir, :beaconDB, :filterFile, :parseResults, :userDir, :dirs, :files, :inria, :subStrings, :dataDir, :tmln_path, :beacon_key, :imps, :keywords, :adInParam, :rtbCompanies, :browsers
	
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
		@files['parseResults']=@dirs['rootDir']+"results.out"
		@files['priceTagsFile']=@dirs['adsDir']+"priceTags"
		@files['devices']=@dirs['adsDir']+"devices.csv"
		@files['size3rdFile']=@dirs['adsDir']+"sizes3rd.csv"
		@files['adParamsNum']=@dirs['adsDir']+"adParamsNum.csv"
		@files['restParamsNum']=@dirs['adsDir']+"restParamsNum.csv"
		#@files['adDevices']=@dirs['adsDir']+"adDevices.csv"
		#@files['userFile']=@dirs['userDir']+"userAnalysis.csv"
		#@files['publishers']=@dirs['adsDir']+"publishers.csv"
		@files['leftovers']="leftovers.out"
		@files['formatFile']="format.in"
		@filterFile=@resources+'disconnect_merged.json'

		#KEYWORDS
		@beacon_key=["beacon","pxl","pixel","adimppixel","data.gif","px.gif","pxlctl"]

		@imps=["impression","_imp","/imp","imp_"]

		@keywords=["price","pp","pr","bidprice","bid_price","bp","winprice", "computedprice", "pricefloor",
		               "win_price","wp","chargeprice","charge_price","cp","extcost","tt_bidprice","bdrct",
		               "ext_cost","cost","rtbwinprice","rtb_win_price","rtbwp","bidfloor","seatbid"]

		@inria={ "rfihub.net" => "ep","invitemedia.com" => "cost",#,"scorecardresearch.com" => "uid" 
				"ru4.com" => "_pp","tubemogul.com" => "x_price", "invitemedia.com" => "cost", 
			"tubemogul.com" => "price", #"bluekai.com" => "phint", 
			"adsrvr.org" => "wp",  
			"pardot.com" => "title","tubemogul.com" => "price","mathtag.com" => "price",
			"adsvana.com" => "_p", "doubleclick.net" => "pr", "ib.adnxs.com" => "add_code", 
			"turn.com" => "acp", "ams1.adnxs.com" => "pp",  "mathtag.com" => "price",
			"youtube.com" => "description1", "quantcount.com" => "p","rfihub.com" => "ep",
			"w55c.net" => "wp_exchange", "adnxs.com" => "pp", "gwallet.com" => "win_price",
			"criteo.com" => "z"}

		# ENHANCED BY ADBLOCK EASYLIST
		@subStrings=["/Ad/","pagead","/adv/","/ad/","ads",".ad","rtb-","adwords","admonitoring","adinteraction",
					"adrum","adstat","adviewtrack","adtrk","/Ad","bidwon","/rtb"] #"market"]	

		@rtbCompanies=["adkmob","green.erne.co","bidstalk","openrtb","eyeota","ad-x.co.uk",
				"qservz","hastrk","api-","clix2pix.net","exoclick"," clickadu","waiads.com","taptica.com","mediasmart.es"]

		@adInParam=["ad_","ad_id","adv_id","bid_id","adpos","adtagid","rtb","adslot","adspace","adUrl", "ads_creative_id", 
				"creative_id","adposition","bidid","adsnumber","bidder","auction","ads_",
				"adunit", "adgroup", "creativity","bid_","bidder_"]

		@browsers=['dolphin', 'gecko', 'opera','webkit','mozilla','gecko','browser','chrome','safari']
	end

	def column_Format()
		return @column_Format[@traceFile]
	end
end
