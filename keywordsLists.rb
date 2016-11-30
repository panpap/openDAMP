class KeywordsLists
	attr_accessor :beacon_key, :rtbMacros, :sameParty, :adCompaniesCat, :filetypes,:disconnect, :cookiesync, :types, :imps, :manualCats, :keywords, :inria, :adInParam, :rtbCompanies, :subStrings, :browsers
	
	def initialize(external,defs)
		@defines=defs
		@adCompaniesCat={"host.com"=>[]}
		@rtbMacros={
			"dsp"=>{"adnxs.com"=>"pubclick","mopub.com"=>"bidder_name","metamx.com"=>"bidder_name","w55c.net"=>"ei","mythings.com"=>"adnclk","taptapnetworks.com"=>"bidid", "mathtag.com"=>"3pck","qservz.com"=>"click3rd","contextweb"=>"cwu"},
			"adx"=>{"mediasmart.es"=>"exchange","w55c.net"=>"rtbhost"},

			"pubs"=>{"mopub.com"=>"pub_name","metamx.com"=>"pub_name","casalemedia.com" => "n", "rfihub.com"=>["pe","p"], "contextweb.com"=>["referrer","cwr"],"adnxs.com"=>"referrer","w55c.net"=>"s", "rtbfy.com"=>["domain","utm_source"], "taggify.net"=>["refdomain", "domain","utm_source"],"adsrvr.org"=>"td_s","ero-advertising.com"=>"document","amazonaws.com"=>"referer_url_enc","media.net"=>["requrl","domain"],"revsci.net"=>["referrer","domain"],"liverail.com"=>"url","moatads"=>"j","brandsmind.com"=>"ru"},

			"sizes"=>{"turn.com"=>"l","get.it"=>"size","contextweb"=>["cf","dm"],"mediasmart.es"=>"size","amazonaws.com"=>"creative_size", "moatads.com"=>"zMoatSZ","media.net"=>"size","taptica.com"=>"tt_size","technoratimedia.com"=>"sz"},
			"ssp"=>{"appflood.com"=>"ssp_name"},
			"position"=>{"moatads.com"=>"zMoatPS"}}

		@beacon_key=["beacon","adimppixel","pxlctl","1x1","1by1"]
	
		@filetypes={".avi"=> "video", ".doc"=>"text", ".htm"=>"html", ".html"=>"html", ".jpg"=>"image", ".jpeg"=>"image", ".png"=>"image",
					".bmp"=>"image",".js"=>"script",".css"=>"styling",".gif"=>"gif",".json"=>"data","xml"=>"data",".mpeg"=>"video",".txt"=>"text",
					".wav"=>"video", ".swf"=>"video",".mp3"=>"video",".mp4"=>"video",".ttf"=>"styling",".webm"=>"video",".webp"=>"image",
					".eps"=>"image",".ajax"=>"script",".midi"=>"video",".mid"=>"video",".mpg"=>"video",".tiff"=>"image",".php"=>"html",
					".woff"=>"styling",".mov"=>"video",".qt"=>"video",".asp"=>"html", ".jsp"=>"html", ".pdf"=>"text",".pixel"=>"image",
					".ppt"=>"text",".pptx"=>"text",".zip"=>"data",".rar"=>"data",".vlc"=>"video",".ram"=>"video",".zlib"=>"video",".pjpeg"=>"image",
					".dhtml"=>"html",".svg"=>"image",".woff2"=>"styling",".aspx"=>"html",".ashx"=>"html",".img"=>"image",".jsonp"=>"data",
					".csx"=>"script",".otf"=>"styling",".sjs"=>"script"}
		
		@types={"*" => "other", "none" => "other" ,"application/x-woff" => "styling", "application/font-woff" => "styling", 
			"application/font-woff2" => "styling", "application/javascript" => "script", "application/json" => "data", 
			"application/octet-stream" => "video", "application/vnd.ms-fontobject" => "styling" ,"application/x-font-ttf" => "styling", 
			"application/x-font-woff" => "styling", "video/mp4" => "video",
			"application/x-shockwave-flash" => "video" ,"application/x-www-form-urlencoded" => "html", "font/ttf" => "styling", 
			"font/woff2" => "styling", "image/bmp" => "image", "image/gif" => "gif", "video/webm" => "video",
			"text/plaincharset=utf-8"  => "text", "text/xml"=>"data", "font/opentype"  => "styling", "font/woff" => "styling" ,
			"no-cache" => "other", "application/x-font-opentype"  => "styling", "image/jpeg" => "image", "image/jpg" => "image" ,
			"application/xml" => "data", "application/font-ttf" => "styling", "application/hal+json"=>"data", 
			"application/x-font-truetype" => "styling", "application/x-gzip"=>"video", 
			"application/x-mpegurl"  => "video", "binary/octet-stream"  => "video", "content/unknown"=>"other", "video/x-msvideo"=>"video",
			"application/zlib"=>"video", "font/truetype"  => "styling", "image/" => "image", "text/x-js"=>"script", "video/mpeg"  => "video", 
			"image/pjpeg" => "image", "image/png" => "image" ,"image/svg+xml" => "image", "application/vnd.apple.mpegurl" =>"video",
			"image/webp" => "image", "text/css" => "styling", "text/css;" => "styling", "application/x-javascript"  => "script" ,
			"text/html" => "html", "application/ecmascript"  => "script", "font/x-woff"  => "styling",
			"*/*"  => "other", "multipart/mixed" => "other", "text/html-by-ajax" => "html", "application/x-font-otf"  => "styling" ,
			"text/javascript" => "script", "text/json" => "data", "text/plain" => "text", "text/x-json" => "data"}

		@imps=["impression","_imp","/imp","imp_"]

		@manualCats={"flix360.com"=>"Analytics","exelator.com"=>"Analytics","mythings"=>"Advertising","w55c.net"=>"Advertising","gosquared.com"=>"Analytics","metamx.com"=>"Advertising","1dmp.io"=>"Advertising",
			"madnetx.com"=>"Advertising", "mpstat.us"=>"Analytics", "gradientx.com"=>"Advertising",
			"akamai.net" => "Content","adap.tv"=>"Advertising","roixdelivery.com"=>"Advertising","roix.com.br"=>"Advertising",
			"akamaiedge.net" => "Content","akamaized.net" => "Content","akamaihd.net" => "Content","edgesuite.net" => "Content",
			"edgekey.net" => "Content","srip.net" => "Content","akamaitechnologies.com" => "Content","akamaitechnologies.fr" => "Content",
			"akamaitech.net" => "Content","akadns.net" => "Content","akam.net" => "Content","akamaistream.net" => "Content", 
			"createjs.com"=> "Content","alephd.com" => "Advertising", "ads.yahoo.com" => "Advertising", "igodigital.com"=>"Analytics",
			"dynamicyield.com"=>"Analytics","bootstrapcdn.com" => "Content","cloudflare.com" => "Content","tiqcdn.com" => "Content",
			"sonobi.com" => "Advertising", "semasio.net"=>"Analytics", "semasio.com"=>"Analytics","rhythmxchange.com" => "Advertising",
			"bidswitch.net" => "Advertising","3lift.com" => "Advertising","triplelift.com" => "Advertising",
			"everesttech.net" => "Advertising","1nimo.com" => "Advertising","4dsply.com" => "Advertising","foresee.com"=>"Analytics",
			"4seeresults.com"=>"Analytics","9cdn.net" => "Content","afsanalytics.com"=>"Analytics","aidata.me"=>"Analytics",
			"advombat.ru"=>"Analytics","abtasty.com"=>"Analytics","albopa.work" => "Advertising","alicdn.com"=>"Content",
			"ani-view.com" => "Advertising", "answerscloud.com"=>"Analytics","apester.com" => "Content","arcpublishing.com" => "Content",
			"arecio.work" => "Advertising", "publited.com" => "Advertising", "arkadiumhosted.com"=>"Content","aspnetcdn.com"=>"Content",
			"audiencemedia.com"=>"Content","bannerflow.com" => "Advertising","beanstock.com" => "Advertising","bleacherreport.net" => "Content", 
			"beanstock.co" => "Advertising", "hstpnetwork.com" => "Advertising", "beatchucknorris.com" => "Advertising", 
			"bidr.io" => "Advertising", "bidtellect.com" => "Advertising", "bidtellectual.com" => "Advertising", 
			"blogsmithmedia.com" => "Content","blueconic.net"=>"Analytics","blueknow.com"=>"Analytics","bnc.lt"=>"Analytics",
			"branch.io"=>"Analytics","centro.net" => "Advertising", "brand-server.com" => "Advertising","brealtime.com" => "Advertising",
			"bttrack.com" => "Advertising", "burt.io"=>"Analytics","clickagy.com"=>"Analytics","cloudzonetrk.com"=>"Analytics",
			"cnt.my"=>"Analytics", "track.e7r.com.br"=>"Analytics", "tracker.bt.uol.com.br"=>"Analytics", "isuba.s8.com.br"=>"Content",
			"iacom.s8.com.br"=>"Content", "metrics.uol.com.br"=>"Analytics", "clearsale.com.br"=>"Analytics", 				
			"clearsalesolutions.com"=>"Analytics","connatix.com" => "Advertising", "connexity.net"=>"Analytics", "ophan.co.uk"=>"Analytics", 
			"cxpublic.com" => "Content","dataradar.es" => "Content","delicious.com" => "Content","directclicksonly.com"=>"Analytics", 
			"dmcdn.net" => "Content","cm.dpclk.com"=>"Analytics","dynad.net" => "Advertising", "edgefonts.net" => "Content",
			"elasticad.net" => "Advertising","fastly.net"=>"Content","freegeoip.net"=>"Analytics","gannett-cdn.com" => "Content",
			"gdmdigital.com" => "Advertising","genesismedia.com" => "Advertising","georiot.com"=>"Analytics", "geni.us"=>"Analytics", 
			"go-mpulse.net"=>"Analytics","apis.google.com"=>"Content","accounts.google.com"=>"Content","gg.google.com"=>"Analytics",
			"goroost.com" => "Content","gssprt.jp" => "Advertising","heatmap.me"=>"Analytics", "heatmap.it"=>"Analytics", 
			"hi-mediaserver.com" => "Content","hotjar.com"=>"Analytics", "hwcdn.net" => "Content","iadbox.com" => "Advertising", 
			"impdesk.com"=>"Advertising","imrk.net"=>"Analytics","ipredictive.com"=>"Advertising","ixiaa.com"=>"Analytics", 
			"janrain.com"=>"Analytics","janrainbackplane.com"=>"Analytics","jquery.com" => "Content","jquerytools.org" => "Content",
			"jsdelivr.net" => "Content","justpremium.com" => "Advertising","jwpcdn.com" => "Content","jwpsrv.com" => "Content",
			"lomadee.com" => "Advertising","madnet.ru" => "Advertising","madnetex.com" => "Advertising","marfeel.com"=>"Analytics",
			"matheranalytics.com"=>"Analytics","media-imdb.com" => "Content","mediavoice.com" => "Advertising","polar.me" => "Advertising",
			"medium.com" => "Content","micpn.com"=>"Analytics","movableink.com"=>"Analytics","video.microcontenidos.com" => "Content",
			"mkbwlcdn.com"=>"Analytics","ml314.com"=>"Analytics","bombora.com"=>"Analytics","mmondi.com" => "Advertising",
			"krxd.net" => "Advertising","nr-data.net"=>"Analytics","newrelic.com"=>"Analytics","omnitagjs.com"=>"Analytics",
			"optimatic.com" => "Advertising","pagefair.com"=>"Analytics","perfectmarket.com"=>"Analytics","taboola.com"=>"Analytics",
			"performgroup.com" => "Content","petametrics.com"=>"Analytics","pippio.com"=>"Analytics","polarmobile.com" => "Advertising",
			"postrelease.com" => "Advertising","nativo.net" => "Advertising","premiereinteractive.com" => "Advertising",
			"pressdisplay.com" => "Content","proxistore.com" => "Advertising","pubnative.net" => "Advertising","pubted.com" => "Advertising",
			"qmerce.com" => "Content","qualtrics.com"=>"Analytics","rackcdn.com" => "Content","rackspacecloud.com" => "Content",
			"qubitproducts.com"=>"Analytics","realtime.co" => "Content","renr.es" => "Content","revee.com"=>"Analytics",
			"richmediastudio.com" => "Advertising","richmetrics.com"=>"Analytics","burtcorp.com"=>"Analytics","smaato.net" => "Advertising",
			"sekindo.com" => "Advertising","sharethrough.com" => "Advertising","simplereach.com"=>"Analytics","siteblindado.com" => "Content",
			"solvemedia.com" => "Advertising","sonataplatform.com" => "Advertising","spingo.com" => "Content","stackadapt.com" => "Advertising",
			"stats.com" => "Content","sub2tech.com"=>"Analytics","sumologic.com"=>"Analytics","taboolasyndication.com"=>"Analytics",
			"tagsrvcs.com"=>"Analytics","tailtarget.com"=>"Advertising","taptapnetworks.com" => "Advertising","liverail.com" => "Advertising","zanox.com" => "Advertising","scmspain.com" => "Advertising","schibsted.es"=> "Advertising"
		}

		@cookiesync=["match","sync","cm","csync","cm.g.doubleclick.net"]

		@keywords=["price","pp","pr","bidprice","bid_price","bp","winprice", "computedprice", "pricefloor",
			           "win_price","wp","chargeprice","charge_price","cp","extcost","tt_bidprice","bdrct",
			           "cost","rtbwinprice","rtb_win_price","rtbwp","bidfloor","seatbid","price_paid","maxPriceInUserCurrency"]

		@inria={ "rfihub.net" => "ep","invitemedia.com" => "cost",#"scorecardresearch.com" => "uid" 
				"ru4.com" => "_pp", "adsrvr.org" => "wp", #"tubemogul.com" => "x_price"  
			"pardot.com" => "title","tubemogul.com" => "price",
			"adsvana.com" => "_p", "doubleclick.net" => "pr", "ib.adnxs.com" => "add_code", 
			"turn.com" => "acp", "ams1.adnxs.com" => "pp",  "mathtag.com" => "price",
			"youtube.com" => "description1", "quantcount.com" => "p","rfihub.com" => "ep",
			"w55c.net" => "wp_exchange", "adnxs.com" => "pp", "gwallet.com" => "win_price",
			"criteo.com" => "z","casalemedia.com"=>"cp"}

		# ENHANCED BY ADBLOCK EASYLIST
		@subStrings=["/Ad/","pagead","/adv/","/ad/",".ad","rtb-","adwords","admonitoring","adinteraction","/ads","videoads",#,"ads/",
					"adrum","adstat","adviewtrack","adtrk","/Ad","bidwon","/rtb","admantx/","adclick","_ad/","/promos/"] #"market"]	

		@rtbCompanies=["adkmob","green.erne.co","mathtag.com","rubiconproject","bidstalk","openrtb","eyeota",
				"ad-x.co.uk","startappexchange.com","atemda.com", "advertising.com", "openx.net","adnxs.com",
				"gwallet.com","tubemogul.com", "ru4.com","turn.com",
				"qservz","hastrk","clix2pix.net","exoclick","adition.com","yieldlab","trafficfactory.biz","clickadu",
				"waiads.com","taptica.com","mediasmart.es","doubleclick.net","adsvana.com","criteo.com","adsrvr.org",
				"pardot.com","invitemedia.com","ads.yahoo.com"]

		@adInParam=["ad_","ad_id","adv_id","bid_id","adpos","adtagid","rtb","adslot","adspace","adUrl", "ads_creative_id", 
				"creative_id","adposition","bidid","adsnumber","bidder","auction","ads_",
				"adunit", "adgroup", "creativity","bid_","bidder_"]

		@browsers=['dolphin', 'gecko', 'opera','webkit','mozilla','gecko','browser','chrome','safari']

		@disconnect,@sameParty=loadExternalFilter(external) if external!=nil
	end

	def loadExternalFilter(external)
		@defines.puts "Loading external Blacklist..."
       	file = File.read(external)
       	json = JSON.parse(file)
        cats=json['categories']
       	filter=Hash.new
        for cat in cats.keys do
                cats[cat].each{ |subCats| subCats.each {|key,values|
                        values.each { |val| val.each{ |doms| (doms.each{|k| filter[k]=cat+"#"+key}) if not doms.is_a?(String)}}}}
        end
#       filter.each {|key,value| puts key+" "+value.to_s}
		sameParty=Hash.new(nil)
		cats.keys.each{|cat| cats[cat].each {|array| array.each{ |company, sites| sites.each{|head, list| list.each{|elem| 
			if sameParty[cat]==nil
				sameParty[cat]=Hash.new 
			end
			sameParty[cat][elem]=head}}}}}
        return filter,sameParty
    end
end
