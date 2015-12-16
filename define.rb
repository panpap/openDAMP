@@trace='100k_trace' #'trace'

#DIRECTORIES
@@dataDir="dataset/"
@@adsDir="parseResults/"
@@resources='resources/'

#FILENAMES
@@impB=@@adsDir+"imprBeacons"
@@adfile=@@adsDir+"ads.out"
@@prices=@@adsDir+"prices"
@@paramsNum=@@adsDir+"paramsNum"
@@devices=@@adsDir+"devices"
@@bcnFile=@@adsDir+"beacons"
@@size3rdFile=@@adsDir+"sizes3rd"
@@paramsNum=@@adsDir+"paramsNum"
@@adDevices=@@adsDir+"adDevices"
@@beaconT=@@adsDir+"beaconsTypes"
@@filterFile=@@resources+'disconnect_merged.json'
@@leftovers="leftovers.out"

#KEYWORDS
@@beacon_key=["beacon","pxl","pixel","adimppixel","data.gif","px.gif","pxlctl"]
@@imps=["impression","_imp","/imp","imp_"]
@@keywords=["price","pp","pr","bidprice","bid_price","bp","winprice", "computedprice", "pricefloor",
                   "win_price","wp","chargeprice","charge_price","cp","extcost","bidprice","bdrct",
                   "ext_cost","cost","rtbwinprice","rtb_win_price","rtbwp","bidfloor","seatbid"]
@@subStrings=["/Ad/","pagead","/adv/","/ad/","ads",".ad","adwords","admonitoring","adinteraction","adrum","adstat","adviewtrack","adtrk","/Ad","bidwon","/rtb"] #"market"]	# ADBLOCK EASYLIST
@@rtbCompanies=["adkmob","green.erne.co","bidstalk","rtb-","openrtb","eyeota","ad-x.co.uk","qservz","hastrk","api-","clix2pix.net","exoclick"," clickadu","waiads.com"]
@@adInParam=["ad_","ad_id","adv_id","bid_id","adpos","adtagid","rtb","adslot","adspace","adposition","bidid","adsnumber","bidder","bidder_id","auction","ads_","creativity"]
@@browsers=['dolphin', 'gecko', 'opera','webkit','mozilla','gecko','browser','chrome','safari']
