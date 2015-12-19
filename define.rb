#TRACES
@@traceFile='100k_trace' #'full_trace'

@@columnsFormat={'100k_trace'=>1, 
		'full_trace'=>1, 	#awazza dataset 6million reqs
		'souneil_trace'=>2} 	#awazza dataset 1million reqs

#DIRECTORIES
@@rootDir=nil
@@dataDir=nil
@@adsDir=nil
@@userDir=nil
@@resources='resources/'

#FILENAMES
@@parseResults=@@rootDir+"parseResults.out"
@@formatFile="format.in"
@@impFile=@@adsDir+"impressions.out"
@@adfile=@@adsDir+"ads.out"
@@prices=@@adsDir+"prices.csv"
@@priceTagsFile=@@adsDir+"priceTags"
@@devices=@@adsDir+"devices.csv"
@@bcnFile=@@adsDir+"beacons.out"
@@size3rdFile=@@adsDir+"sizes3rd.csv"
@@paramsNum=@@adsDir+"paramsNum.csv"
@@adDevices=@@adsDir+"adDevices.csv"
@@beaconT=@@adsDir+"beaconsTypes.csv"
@@userFile=@@userDir+"userAnalysis.csv"
@@filterFile=@@resources+'disconnect_merged.json'
@@publishers=@@dataDir+"publishers.csv"
@@leftovers="leftovers.out"

#KEYWORDS
@@beacon_key=["beacon","pxl","pixel","adimppixel","data.gif","px.gif","pxlctl"]

@@imps=["impression","_imp","/imp","imp_"]

@@keywords=["price","pp","pr","bidprice","bid_price","bp","winprice", "computedprice", "pricefloor",
                   "win_price","wp","chargeprice","charge_price","cp","extcost","tt_bidprice","bdrct",
                   "ext_cost","cost","rtbwinprice","rtb_win_price","rtbwp","bidfloor","seatbid"]

@@inria={ "rfihub.net" => "ep","invitemedia.com" => "cost","scorecardresearch.com" => "uid", 
			"ru4.com" => "_pp","tubemogul.com" => "x_price", "invitemedia.com" => "cost", 
		"tubemogul.com" => "price", "bluekai.com" => "phint", "adsrvr.org" => "wp",  
		"pardot.com" => "title","tubemogul.com" => "price","mathtag.com" => "price",
    	"adsvana.com" => "_p", "doubleclick.net" => "pr", "ib.adnxs.com" => "add_code", 
		"turn.com" => "acp", "ams1.adnxs.com" => "pp",  "mathtag.com" => "price",
    	"youtube.com" => "description1", "quantcount.com" => "p","rfihub.com" => "ep",
    	"w55c.net" => "wp_exchange", "adnxs.com" => "pp", "gwallet.com" => "win_price",
    	"criteo.com" => "z"}

# ENHANCED BY ADBLOCK EASYLIST
@@subStrings=["/Ad/","pagead","/adv/","/ad/","ads",".ad","rtb-","adwords","admonitoring","adinteraction",
				"adrum","adstat","adviewtrack","adtrk","/Ad","bidwon","/rtb"] #"market"]	

@@rtbCompanies=["adkmob","green.erne.co","bidstalk","openrtb","eyeota","ad-x.co.uk",
			"qservz","hastrk","api-","clix2pix.net","exoclick"," clickadu","waiads.com","taptica.com","mediasmart.es"]

@@adInParam=["ad_","ad_id","adv_id","bid_id","adpos","adtagid","rtb","adslot","adspace","adUrl", "ads_creative_id", 
			"creative_id","adposition","bidid","adsnumber","bidder","auction","ads_",
			"adunit", "adgroup", "creativity","bid_","bidder_"]

@@browsers=['dolphin', 'gecko', 'opera','webkit','mozilla','gecko','browser','chrome','safari']

