load 'convert.rb'
load 'trace.rb'
load 'filters.rb'
require 'digest/sha1'

class Core
	attr_writer :window, :cwd
	attr_accessor :database, :skipped
   	@isBeacon=false

	def initialize(defs,filters)
		@defines=defs
		@skipped=0
		@convert=Convert.new(@defines)
		@filters=filters	
		@trace=Trace.new(@defines)
		@options=@defines.options
		@window=-1
		@cwd=nil
		@params_cs=Hash.new(nil)
		@database=nil
	end
	
	def makeDirsFiles()
		@defines.puts "> Creating Directories..., "
		Dir.mkdir @defines.dirs['rootDir'] unless File.exists?(@defines.dirs['rootDir'])
		Dir.mkdir @defines.dirs['dataDir'] unless File.exists?(@defines.dirs['dataDir'])
		Dir.mkdir @defines.dirs['adsDir'] unless File.exists?(@defines.dirs['adsDir'])
		Dir.mkdir @defines.dirs['userDir'] unless File.exists?(@defines.dirs['userDir'])
		Dir.mkdir @defines.dirs['timelines'] unless File.exists?(@defines.dirs['timelines'])	
		@database=Database.new(@defines,nil)
		if @options["database?"]
			@defines.puts "and database tables..."
			@defines.tables.values.each{|fields| @database.create(fields.keys.first,fields.values.first)}
		end
	end

	def analysis
		options=@options['resultToFiles']
		@defines.puts "> Stripping parameters, detecting and classifying Third-Party content..."
		fw=nil
		@defines.puts "> Dumping to files..."
		if options[@defines.files['devices'].split("/").last] and not File.size?@defines.files['devices']
			fd=File.new(@defines.files['devices'],'w')
			@trace.devs.each{|dev| if dev!=-1
					for k in dev.keys
						fd.print dev[k].to_s+"\t"
					end
				end
				fd.puts}
			fd.close
		end
		if options[@defines.files['restParamsNum'].split("/").last] and not File.size?@defines.files['restParamsNum']
			fpar=File.new(@defines.files['restParamsNum'],'w')
			@trace.restNumOfParams.each{|p| fpar.puts p}
			fpar.close
		end
		if options[@defines.files['adParamsNum'].split("/").last] and not File.size?@defines.files['adParamsNum']
			fpar=File.new(@defines.files['adParamsNum'],'w')
			@trace.adNumOfParams.each{|p| fpar.puts p}
			fpar.close
		end
		if options[@defines.files['size3rdFile'].split("/").last] and not File.size?@defines.files['size3rdFile']
			fsz=File.new(@defines.files['size3rdFile'],'w')
			@trace.sizes.each{|sz| fsz.puts sz}
			fsz.close
		end
		total=Thread.new {
			@defines.puts "> Calculating Statistics about detected ads..."
			@defines.puts @trace.results_toString(@database,@defines.tables['traceTable'],@defines.tables['bcnTable'],@defines.tables['advertiserTable'],@filters.getCats)}
		perUserAnalysis()
		total.join
	end

	def findStrInRows(str)
		for val in r.values do
			if val.include? str
				if(printable)
					url=r['url'].split('?')
					Utilities.printRow(r,STDOUT)
				end
				found.push(r)					
				break
			end
		end
	end

	def parseRequest(row)
		if row['ua']!=-1
			mob,dev,browser=reqOrigin(row)		#CHECK THE DEVICE TYPE
			row['mob']=mob
			row['dev']=dev
			row['browser']=browser
			if @options["mobileOnly?"] and mob!=1
				@skipped+=1
				return false
			end		#FILTER ROW
		end
		cat=filterRow(row)
		cookieSyncing(row,cat) if cat!=nil and @options['tablesDB'][@defines.tables["csyncTable"].keys.first]
		return true
	end

	def readUserAcrivity(tmlnFiles)
		@defines.puts "> Loading "+tmlnFiles.size.to_s+" User Activity files..."
		user_path=@cwd+@defines.userDir
		timeline_path=@cwd+@defines.userDir+@defines.tmln_path
		for tmln in tmlnFiles do
			createTmlnForUser(tmln,timeline_path,user_path)
		end
	end

	def createTimelines()
		@defines.puts "> Contructing User Timelines..."
		user_path=@cwd+@defines.userDir
		timeline_path=@cwd+@defines.userDir+@defines.tmln_path
		fr=File.new(@cwd+@defines.dataDir+"IPport_uniq",'r')
		while l=fr.gets
			user=l.chop
			fw=File.new(timeline_path+user+"_per"+(@window/1000).to_s+"sec",'w')
			IO.popen('grep '+user+' ./'+@defines.traceFile) { |io| 
			firstTime=-1
			while (line = io.gets) do 
				h=Format.columnsFormat(line,@defines.column_Format)
				Utilities.separateTimelineEvents(h,user_path+h['IPport'],@defines.column_Format)
				if firstTime==-1
					firstTime=h['tmstp'].to_i
				end
				applyTimeWindow(firstTime,row,fw)
			end }
			fw.close
		end
		fr.close
	end

	def cookieSyncing(row,cat)
		firstSeenUser?(row)
		return if row['status']!=nil and (row['status']=="200" or row['status']=="204" or row['status']=="404" or row['status']=="522") # usually 303,302,307 redirect status
		@params_cs[@curUser]=Hash.new(nil) if @params_cs[@curUser]==nil
		urlAll=row['url'].split("?")
		return if (urlAll.last==nil)
		if not checkCSinParams(urlAll,row,cat)
			checkCSinURI(urlAll,row,cat)
		end
	#	puts row['url']+" "+ids.to_s if ids>0
	end

	def csyncResults()
		if @database!=nil
			@defines.puts "> Dumping Cookie synchronization results..."	
			@trace.dumpUserRes(@database,nil,nil,@filters,@convert)	
		end
	end
#------------------------------------------------------------------------------------------------


	private

	def	checkCSinURI(urlAll,row,cat)
        curHost=Utilities.calculateHost(urlAll.first,nil).split(".")[0] # host without TLD
        if cat==nil
            cat=@filters.getCategory(urlAll,curHost,@curUser)
            cat="Other" if cat==nil
        end
		parts=urlAll.first.split("/")
		for i in 1..parts.size	#skip actual domain
			if @filters.is_it_ID?(nil,parts[i])# and (["turn","atwola","tacoda"].any? {|word| urlAll.first.include? word})
				if @params_cs[@curUser][parts[i]]!=nil
					 prev=@params_cs[@curUser][parts[i]].last
					if @filters.getRootHost(prev['host'],nil)!=@filters.getRootHost(curHost,nil)
						it_is_CM(row,prev,curHost,[parts[i-1],parts[i]],urlAll,-1,cat,-1)
					end
				else	#first seen ID
					@params_cs[@curUser][parts[i]]=Array.new
				end
				@params_cs[@curUser][parts[i]].push({"url"=>urlAll,"paramName"=>parts[i-1],"tmstp"=>row['tmstp'],"cat"=>cat,"status"=>row["status"],"host"=>curHost,"httpRef"=>row["httpRef"]})
			end
		end
	end

	def it_is_CM(row,prev,curHost,paramPair,urlAll,ids,curCat,confirmed)
#prevTimestamp|curTimestamp|hostPrev|prevCat|hostCur|curCat|paramNamePrev|userID|paramNameCur|possibleNumberOfIDs|prevStatus|curStatus|allParamsPrev|allParamsCur
		prevHost=prev['host']
		params=[@curUser,prev['tmstp'],row['tmstp'],prevHost,prev['cat'],curHost,curCat,prev["paramName"], paramPair.last, paramPair.first, prev['status'],row["status"],ids,confirmed,prev['url'].last.split("&").to_s, urlAll.last.split("&").to_s, prev["url"].first+"?"+prev["url"].last,row["url"], prev['httpRef'], row['httpRef']]
		id=Digest::SHA256.hexdigest (params.join("|")+prev['url'].first+"|"+urlAll.first)
		@trace.users[@curUser].csync.push(params.push(row["mob"]))
		@trace.users[@curUser].csync.push(params.push(row["dev"].to_s))
		@trace.users[@curUser].csync.push(params.push(row["browser"]))
		@trace.users[@curUser].csync.push(params.push(id))
		if @trace.users[@curUser].csyncIDs[paramPair.last]==nil
			@trace.users[@curUser].csyncIDs[paramPair.last]=0
		end
		
		if 	@trace.users[@curUser].csyncHosts[prevHost+">"+curHost]==nil
			@trace.users[@curUser].csyncHosts[prevHost+">"+curHost]=Array.new
		end
		@trace.users[@curUser].csyncHosts[prevHost+">"+curHost].push(confirmed)
		@trace.users[@curUser].csyncIDs[paramPair.last]+=1
		@trace.cooksyncs+=1
	end

	def checkCSinParams(urlAll,row,cat)
		exclude=["cb","token", "nocache"]
		confirmed=0
		ids=0
		found=false
		fields=urlAll.last.split('&')
		return if fields.size>4 # usually there are very few params_cs (only sessionids)
		for field in fields do
            paramPair=field.split("=")
            if @filters.is_it_ID?(paramPair.first,paramPair.last) and not (exclude.any? {|word| paramPair.first.downcase==word})
                ids+=1
                curHost=Utilities.calculateHost(urlAll.first,nil).split(".")[0] # host without TLD
confirmed+=1 if @params_cs[@curUser].keys.any?{ |word| paramPair.last.downcase.eql?(word)} 
                if cat==nil
                    cat=@filters.getCategory(urlAll,curHost,@curUser)
                    cat="Other" if cat==nil
                end
                if @params_cs[@curUser][paramPair.last]==nil #first seen ID
                    @params_cs[@curUser][paramPair.last]=Array.new
                else    #have seen that ID before -> possible cookieSync
                    prev=@params_cs[@curUser][paramPair.last].last
                    if @filters.getRootHost(prev['host'],nil)!=@filters.getRootHost(curHost,nil)
                    	it_is_CM(row,prev,curHost,paramPair,urlAll,ids,cat,confirmed)
						found=true
                    end
                end
				@params_cs[@curUser][paramPair.last].push({"url"=>urlAll,"paramName"=>paramPair.first,"tmstp"=>row['tmstp'],"cat"=>cat,"status"=>row["status"],"host"=>curHost,"httpRef"=>row["httpRef"]})
            end
        end
		return found
	end


	def firstSeenUser?(row)
		@curUser=row['IPport']
		if @trace.users[@curUser]==nil		#first seen user
			@trace.users[@curUser]=User.new	
		end
		if @trace.users[@curUser].uIPs[row['uIP']]==nil
			@trace.users[@curUser].uIPs[row['uIP']]=1
		else
			@trace.users[@curUser].uIPs[row['uIP']]+=1
		end
	end

	def	createTmlnForUser(tmln,timeline_path,user_path)
		if not tmln.eql? '.' and not tmln.eql? ".." and not File.directory?(user_path+tmln)
			fr=File.new(user_path+tmln,'r')
			fw=nil
			firstTime=-1
			bucket=0
			startBucket=-1
			endBucket=-1
			c=0
			while line=fr.gets
				r=Format.columnsFormat(line,@defines.column_Format)
				mob,dev,browser=reqOrigin(r)
				row['mob']=mob
				row['dev']=dev
				row['browser']=browser
				if browser!=nil
					if firstTime==-1
						fw=File.new(timeline_path+tmln+"_per"+@window.to_s+"msec",'w')
						firstTime=r['tmstp'].to_i
						startBucket=firstTime
					end
					nbucket=applyTimeWindow(firstTime,r,fw)
					if bucket!=nbucket						
						fw.puts "\n"+startBucket.to_s+" : "+endBucket.to_s+"-> BUCKET "+bucket.to_s
						fw.puts @trace.results_toString(@database,nil,nil)+"\n"
						bucket=nbucket
						@trace=Trace.new(@defines)
						startBucket=r['tmstp']
					end
					@curUser=r['IPport']
					if @trace.users[@curUser]==nil		#first seen user
						@trace.users[@curUser]=User.new	
					end
					filterRow(r)
					@trace.rows.push(r)
					fw.puts c.to_s+") BUCKET "+bucket.to_s+"\t"+r['tmstp']+"\t"+r['url']+"\t"+r['ua']
					endBucket=r['tmstp'].to_i
					c+=1
				end
			end
			if startBucket!=-1 && endBucket!=-1
				fw.puts "\n"+startBucket.to_s+" : "+endBucket.to_s+"-> BUCKET "+bucket.to_s
				fw.puts @trace.results_toString(@database,nil,nil)+"\n"
			end
			@trace=Trace.new(@defines)
			fr.close
			if fw!=nil
				fw.close
			end
		end
	end

	def applyTimeWindow(firstTime,row,fw)
		diff=row['tmstp'].to_i-firstTime
		wnum=diff.to_f/@window.to_i
		return wnum.to_i
	end	

	def reqOrigin(row)
		#CHECK IF ITS MOBILE USER
		mob,dev=@filters.is_MobileType?(row)   # check the device type of the request
		if mob==1
			@trace.mobDev+=1
		end
		#CHECK IF ITS ORIGINATED FROM BROWSER
		browser=@filters.is_Browser?(row,dev)
		if browser!= "unknown"
			@trace.fromBrowser+=1
		end		
#		dev=dev.to_s.gsub("[","").gsub("]","")
        @trace.devs.push(dev)
		return mob,dev,browser
	end		

	@@lastSeenTmpstp=nil
	def isItDuplicate?(row)
		return false if not @options["removeDuplicates?"]
		if @@lastSeenTmpstp==row['tmstp'] #same row
			return false
		else
			@@lastSeenTmpstp=row['tmstp']
		end
		url=row['url'].split("?")
		return false if url.size==1
		footPrnt=Digest::SHA256.hexdigest(url.last)
		if @trace.paramDups[footPrnt]==nil
			@trace.paramDups[footPrnt]=Hash.new
			@trace.paramDups[footPrnt]["url"]=row['url'] 
			@trace.paramDups[footPrnt]["count"]=0
			@trace.paramDups[footPrnt]['tmpstp']=Array.new
		end
		@trace.paramDups[footPrnt]["count"]+=1
		@trace.paramDups[footPrnt]["tmpstp"].push(row['tmstp'])
		return true if @trace.paramDups[footPrnt]["count"]>1 # It is indeed duplicate	
		return false
	end

	def categorizeReq(row,url)	
		publisher=nil
		host=row['host']
		type3rd=@filters.getCategory(url,host,@curUser)
        @isBeacon=false
        params, isAd=checkForRTB(row,url,publisher,(type3rd.eql? "Advertising"))      #check ad in URL params
        if isAd==false	#noRTB
	        if @filters.is_Beacon?(row['url'],row['type']) 		#findBeacon in URL
        	    beaconSave(url.first,row)
				collectAdvertiser(row) if type3rd=="Advertising" #adRelated Beacon
				type3rd="Beacons"
        	else #noRTB no Beacon
				isAd=detectImpressions(url,row)
			end
		end
		if isAd==true
			type3rd="Advertising"
		end
		return type3rd,params
	end

	def filterRow(row)
		firstSeenUser?(row)
		type3rd=nil
		@isBeacon=false
		url=row['url'].split("?")
		@trace.sizes.push(row['dataSz'].to_i)
		type3rd,params=categorizeReq(row,url)
		noOfparam=params.size
		if type3rd!=nil and type3rd!="Beacons" # 3rd PARTY CONTENT
			collector(type3rd,row)
			@trace.party3rd[type3rd]+=1
			if not type3rd.eql? "Content"
				if type3rd.eql? "Advertising"
					ad_detected(row,noOfparam,url)
				else # SOCIAL or ANALYTICS or OTHER type
					@trace.restNumOfParams.push(noOfparam.to_i)
				end
			else	#CONTENT type
				@trace.restNumOfParams.push(noOfparam.to_i)
			end
		else	# Rest
			type3rd="Other"
			@trace.party3rd[type3rd]+=1
			if (row['browser']!="unknown") and (@options['tablesDB'][@defines.tables["publishersTable"].keys[0]] or @options['tablesDB'][@defines.tables["userTable"].keys[0]])
				@trace.users[@curUser].publishers.push(row)
			end
			#Utilities.printStrippedURL(url,@fl)	# dump leftovers
			collector(type3rd,row)
		end
		collectInterests(url.first,type3rd)
		return type3rd
	end

	def collectInterests(url,type3rd)
		if @options['tablesDB'][@defines.tables["visitsTable"].keys.first] and (type3rd=="Other" )#or type3rd=="Content") 
			site=url
			site=url.split("://").last if url.include? "://"
			domain=site.split("/").first
			@trace.users[@curUser].pubVisits[domain]=0 if @trace.users[@curUser].pubVisits[domain]==nil
			@trace.users[@curUser].pubVisits[domain]+=1
			topics=nil
			if topics!=nil and topics!=-1
				if @trace.users[@curUser].interests==nil
					@trace.users[@curUser].interests=Hash.new(0)
				end
				topics.each{|key, value| @trace.users[@curUser].interests[key]+=value}
			end
		end
	end

	def collector(contenType,row)
		type=row['type']
		if @options['tablesDB'][@defines.tables["userTable"].keys.first]
			@trace.users[@curUser].size3rdparty[contenType].push(row['dataSz'].to_i)
			@trace.users[@curUser].dur3rd[contenType].push(row['dur'].to_i)
		end
		if type!=-1 and @options['tablesDB'][@defines.tables["userFilesTable"].keys.first]
			if @trace.users[@curUser].fileTypes[contenType]==nil
				@trace.users[@curUser].fileTypes[contenType]={"data"=>Array.new, "gif"=>Array.new,"html"=>Array.new,"image"=>Array.new,"other"=>Array.new,"script"=>Array.new,"styling"=>Array.new,"text"=>Array.new,"video"=>Array.new} 
			end
			@trace.users[@curUser].fileTypes[contenType][type].push(row['dataSz'].to_i)
		end
	end

	def perUserAnalysis
		if @database!=nil
			@defines.print "> Dumping per user results to "
			if @options["database?"]
				@defines.puts "database..."
			else
				@defines.puts "files..."
			end
			durStats={"Advertising"=>{},"Beacons"=>{},"Social"=>{},"Analytics"=>{},"Content"=>{},"Other"=>{}}
			sizeStats={"Advertising"=>{},"Beacons"=>{},"Social"=>{},"Analytics"=>{},"Content"=>{},"Other"=>{}}
			@trace.dumpUserRes(@database,durStats,sizeStats,@filters,@convert)
		end
	end

    def detectPrice(row,keyVal,numOfPrices,numOfparams,publisher,isAdCat,https)     	# Detect possible price in parameters and returns URL Parameters in String
		domainStr=row['host']
		domain,tld=Utilities.tokenizeHost(domainStr)
		host=domain+"."+tld
		return false if ["elpais.com","cr9.party","currentlyobsessed.me","quantcount.com","taggify.net","gradientx.net","7ba.biz","ebay","brazzers.com","ilius.net","hm.com","gameforge.com","dogpile.com","info.com","baidu.com","brandsmind.com","infospace.com","infospace.com","famehosted.comforo20.com","nanigans.com","webcal.fiyhd.com","zalando.es","forociudad.com","000a.biz","01net.com","110school.ru","115animal.com","1201gaming.com","123chs.com","123internet.gr","126.net","12iacc.org",
		"15fgeeb88.com","15minute-paydayloans.co.uk","2525menkyo.com","2playergames.co.nz","33b.mobi","33b.ru","3jedareh.com","3palms.ch","3show.biz","50webs.com","51cto.com",
		"55club.cn","56k.us","7gamers.com.au","9555.xn--p1ai","aaa.yt","aanorthflorida.org","aareklama.ru","aaronveryard.com","abdullahshwaikah.com",
		"abimbolajunaid.org","abnamrobank.ca","a-body.net","aboutthedomain.com","aceitar.co","ach22.ru","acpcwc.org","actiondecareme.ch","activezeroenergy.mobi","actupbasel.org","acuityplatform.com","ad2links.com","additionplus.com","adgo.by","admedicine.org","adm-socially-stage.com","adoption.com","adorablebabyanimals.com","adriangrosser.de","adsmrkt.com","advenbbs.net","adwin.com","aecoimbracentro.pt","aerial.dance","aeromodelismovirtual.com","aeropostale.com","africandrummingtownsville.com","afro360news.com","afrohelse.no","agenciaorigem.com.br","aiellocalabro.org","aisyiyahkotakediri.org","aktive-fans.de","al5hatib.com","alaskajournal.com","albinoblacksheep.com","al-daa.com","al-dalel.com","alepouditsa.gr","allcrimea.net","allencountygop.com","almouna.org","almubassir.com","altecaluminio.com.br","alternatehistory.com","alternatehistory.org","altrarovereto.it","alvsjomiljorad.se","amatube.eu","ambig.com","amlakyousefi.com","anambrayouthsassociation.org","ancestry.com.au","andrepires.net","androidcv.com","angelencountervideos.com","animando3d.com","animeshko.ru","annikalangvad.dk","anoprienko.com","antichat.ru","antondanielsson.se","anumex.com","api-01.com","apkthing.com","appropedia.org","apvrovra.in","aratingaja.info","arayeshsepideh.com","arcadiafloresville.mobi","arkresidential.mobi","arousshow.com","artisticalstudios.com","aryohadi.com","asafesite.com","asahi.com","asesoramosonline.com","asolfsskali.is","attorneysdot.net","auctionserver.net","aught.jp","augies-place.com","aurakikoto.hu","auto-t.ru","avhsalumni.org","avindar.net","avradinis.gr","avtox.net","ayland.ru","ayqingenieros.com","b2fireflies.com","babatemple.org","badcaps.net","bahrainstrategiccenter.org","baiduyun.me","bailefelix.net","bali-99.com","bali-99.com","balletshmallet.com","bangaloretdpforum.com","barbarian-games.com","bariskina.ru","baseruralconsultoria.com.br","baxta.com.au","bbwurls.com","bdsm-zone.com","beaba.info","beartales.me","beautyassociation.org","beckertalk.com","beefit.ir","belkhiria.net","belongsinamuseum.com","bel.tr","benhofgroup.com","biceliyiz.biz","biddingx.com","bidhopper.com","biegowkiwesola.org","bienesymaquinaria.com","big-nose.com","bildungswelten.info","binary-trading-video.com","binjiangguoji.com","birdflyinsky.com","bit-multimedia.com","bizland.com","biztechskopje.com","blablaland.com","blackdecor.ir","blackpointforum.com","bluefly.com","bmu.fr","boarderking.it","boardreader.com","boat.ag","boatdealers.net","bodyzmbalance.com","bokharaco.com","bokmassan.se","bonstempos.pt","bookmerken.de","bookmrk.us","boshcraft.com","boxpicks.com","brasanddrawls.com","braveblog.com","bravenet.com","brimoto-group.co.uk","brokenbay.org","brookshiredental.com","bruenefeld.de","bspindonesia.com","buddylead.com","buenapark.com","bugamark.com","bugi.ch","bullseyesport.com","bullshido.net","businesscatalyst.com","businessplaymate.com","buslaev.ru","by616.com","cablel.ro","cafemagellan.no","california-security-guard-card.com","caminoplata.com","cancionesdetelenovelas.com","carissaputri.com","casadaeira.org","casadellibro.com","casertasette.com","cassandra2.com","catholique.fr","caxapok.kz","cceresearch.com","cdco07.fr","cehcharlotte.com","cellebiz.com","centerfish.ru","centili.com","ceramicasferret.com","ceres21.org","cgia.us","ch0p.me","charite-bioinformatik.de","charlestonbattery.com","charlestonretirement.net","chatakorbielow.pl","chathouse3d.com","chebup.com","chevrim.com","chicagoscubaschool.com","childpsy.org","china-nh.com","chinood.ir","choice-ny.com","chromecoaster.com","ci123.com","cidadedeluanda.net","cifconsultor.com","cinemaklub.ru","cityblm.org","cityofbartow.net","cityofcashmere.org","cityofvacaville.com","citystudios.se","clanstruchhi.com","classicshop.com.br","clinmedres.org","cmckorea.org","cmsfarsi.net","cncyiling.com","cnujsrh.com","coachpattyusa.net","codsana.com","cogonline.net","co.il","cojinesterapeuticos.com.mx","comfortplusacheating.com","comfortwarrior.com","com.ng","com.nu","com.pe","com.pl","compraenquart.com","com.tr","com.tt","comunicadoressf.com","conaxtechnologies.de","conceptproductionz.com","concreteinstitute.com.au","confirmit.com","consolewars.de","constructionnews.co.nz","cookinggamesfun.com","cool-hdwallpapers.net","cornflakes3d.com","cort.as","corvallisoregon.gov","costamesaca.gov","co.th","co.ua","co.ug","couponyield.com","cpt-co.com","crazy-games.eu","creationpointdecroix.com","creativecdn.com","crimson-head.com","croet.com","cruiselinesjobs.com","csalazar.org","cssoc.co.uk","csusmhistory.org","ctassist.com","ctwins.com.br","cuahangvanphongpham.com","cult.cu","cunysportsreport.com","curlingzone.com","custeel.com","cw.cx","cwsurf.de","czdesign.ca","danesh-afagh.com","danicapatrick.uk","danzanet.org","darinelly.com","darkvillains.com.br","dashti10.ir","datab.us","datahub.io","davidicke.com","dawanda.com","dawnbreaker.com","deadsea-beach.com","deathcontrol.de","dechaleira.com","decorativemodern.ir","dedecms.com","dedibox.fr","denalimasonry.com","derstandard.at","desertflor.com","designdogs.net","designperlacasa.it","destinationdominica.org","devatics.com","dewitt.at","diabetesforums.nl","di.al","diamondfest.com.br","dicoperso.com","dieselpowerconnections.com","difesadelsuolo.it","digitvinfo.es","digtenu.dk","diigo.com","dimensioneautobacoli.com","di-nisio.de","dipyourcar.com","discusslinks.com","disney.co.uk","distanakpacitan.org","distro.cl","djsirpee.com","djstixxx.be","dlasmoras.com","docall.biz","doc.gov","documentroot.com","dofcoffee.com","dogengine.com","dojin.com","domes-dos.de","dom-kedra.ru","doris-schlee.de","doyoukiss.com","dreamdemons.net","drustvo-ravnateljev.si","dsscteam.com","dtnt.info","dubai2iran.com","dveri-clin.ru","dzagi.com","eagleweb.xyz","earthdemo.com","easpiattaforme.it","easytestbook.com","eburgclub.ru","echodrama.net","economicstressindex.com","edesk.jp","edublogs.org","edu.bo","educatedbyerrors.de","edu.ec","edu.ng","edurm.ru","edu.ru","effelunga.net","egipto.com","egoruntulusohbet.com","egpet.net","ekspertbudowlany.pl","elearningnews.net","electrocomponents.com","elenacuadrado.com","elettraautomazioni.com","elforocristiano.org","elijahadamband.com","elite-sports.ru","elleryhomestyles.com","ellwoodcanyonfarms.com","elrapado.com","elynx.nl","emailretargeting.com","emrysdesigns.com","energysolutions4you.com","epicor.com","ereadernation.com","ero-advertising.com","escueladefinanzasreal.com","esearch.ru","eshgh-20.tk","eso-wiki.org","esquizopedia.com","estimatedwebsite.es","etece.es","etiquetasexpress.com.mx","evansvilleapc.com","eventful.com","evobsol.com","evolve-worldwide.com","excursionesproviatur.com","extrasait.ru","ezbbs.net","ezebee.com","fanbase.com","fansub.tv","fantasiediariel.com","farmbaskit.com","fashionspot.ro","fastenopfer.com","fatcountry.com","fbcdurant.org","fcpe34.org","feber.es","fgn-guild.com","fidespesetamor.com","figaroenzo.de","fightsol.com","filmdatabase.dk","fincen.gov","finecooking.com","firstchoicecu.org","fitile2.com","fjbnwy.com","flashbored.com","flyingelephantuae.com","food-dog.ru","foodservicenews.net","fordoo-gypsum.com","forexsoul.com","formacionyoficios.com","forumbiodiversity.com","forumciclismo.net","forumerz.com","fotodimension.com.ar","fotonesta.com","foxtrot-international.com","francemetal.com","frankeltutors.com","franslivre.net","fraudnet.info","freakytrigger.co.uk","freehostia.com","freehost.pl","frenadesonoticias.org","frenzee.org","frontrowlingeries.com","fuckurgf.com","fullybookedonline.com","fundacaonokia.org","fungaiolisiciliani.it","funlix.de","funtastic-party.de","fuu8.com","fzhufu.com","g99games.com","gabrielcds.net","gag.pw","galaxyrc.es","galeriedon.com","game-baby.net","gamecookie.com","gameloft.com","gamersyard.com","gamingbasement.com","gangsterparadise.co.uk","gapeland.biz","gastroclinicaan.com.br","gatzgatz.com","gc-gip.ru","gcmforex.com","gemssensors.com","genanalalban.com","geofilmebi.in","geo-samyaro.com","gerakanaktif.com","german-chinese.eu","gerva.lt","ggo.vn","gilgameshsecurity.com","giochaviet.com","giochigratis.info","glink.jp","globalalsocialnetwork.com","globat.com","globo.com","glum-shop.ru","go4shop.vn","goingviralposts.net","goku-games.com","golawphuket.com","golpluksut.com","gonulpervaneleri.org","goodreads.com","goodtime.ir","goodtofu.org","goshootinggames.com","go.th","gotop100.com","gov.cn","gov.tr","gov.uz","gowhiteboardhighered.net","goxl.me","graecusterra.ru","grandsolarinc.com","grassrootdevelopmentinitiative.com","gratisplay.it","grepolis.com","gr.jp","growswedes.com","grupo-cpi.com","gtheatingltd.co.uk","gti16.com","gtradersoftware.com","guate360.com","guayaco.com","guiafast.com","guildwars2.com","gulfindustryfair.com","gymnasticscrosstraining.com","h1z1hq.com","hauori.com","hausfrauen-ganz-privat.de","h-a-z.org","headstats.com","healing-handssanctuary.co.uk","healthybodyspot.com","heavyhosts.com","heimishchat.com","hellotranny.com","herosjourneyrpg.com","herters-hun.de","hideurl4you.com","hidn.com.au","hillsessay.com","hilltopperalumni.com","hitag.pt","hitmuzik.ru","hk-eg.org","hobbit1.info","hofzakelijk.nl","holierthanthou.org","hollywood43.ru","hornes.org","hostel108.ru","host-h.net","hotelrealestatenews.com","housingdata.org","houstonlimolinks.com","hprlnk.ru","htmklaverjas.nl","humingpeng.com","humsitaray.tv","hundekrankengymnastik-kraus.de","hune.com","hyperdrivei.com","i-altai.ru","iandagroup.com","ibbycongress2014.org","iberfit.pt","ibis21.info","idealmaxsolution.com","ideatutoring.org","idforum.org","idg.com.au","ifokus.se","igrejaprogresso.com.br","ikpa-usa.org","iksv.org","ilbarone.de","ileaxepandalaira.com.br","imagevenue.com","immobiliensanierung-amboss.de","imozaic.com","imusinstitute.net","indiaserver.com","info.pl","informe16.com","informeproductora.com","informus.se","infoturcuba.cu","in.gov","inkey.in","in-memory-of-you.com","innokmg.kz","intcommerce.co.uk","internationalsexguide.info","involved-gaming.com","ioffer.com","ipc-chicago.com","ipswichalebrewery.com","iptorrents.com","ira.li","iraqiyeen.com","iriscatering.no","iris-web.com","isafacts.com","isa.ru","iscaguadeloupe.com","iscleaner.com","iscool.pl","isenturk.com","is.gd","isggroup.eu","iskra-orsk.ru","isolar.com.mx","italkursy.ru","itechol.com","itesin.cz","ithink.pl","itprobit.com","itsyurl.tk","ivpc.org","iwebreader.com","iwix.net","iwt.pl","izmail.es","jalaan.com","jamp.gr","janimakinen.com","jhku.net","jjsapido.com","jnbridge.com","joerg-sachse.de","jonfelix.net","joshaaronwood.com","jsycgx.com","juegosdemariobros.tv","juegosdevestir.co.uk","jumbobbs.com","justusboys.com","k12educationtips.com","kadangcoffee.com","kaktusit.com","kanaken.net","kannikar.com","karelawyer.com","katdev-development.com","katstron.pl","kavkazinfo.net","kayoobi.com","kekenet.com","kelchambredhotes.fr","kelurahansungaibesar.info","kenyans.us","keralasbelleza.es","keymachine.de","khasanahminang.com","khilmashkri.org","kickoffcoverage.com","kidssofashop.com","kinghost.net","kisaltiyor.com","kit.edu","klankbordcmd.nl","kleintjesgoed.be","knyajna.com","koatsystems.com","kobec.org","koleksix.com","kompass.com","komsol.se","koperasiadil.com","koppelgoor.nl","kotori.me","krakataujogja.com","krxd.net","ksac.co.kr","kus-jambi.com","l5l5.net","lafranceapoil.com","lagonaki.com","lanthrax.com","larednetwork.com","lastwagenspiele.com","latinchat.com.mx","1 latinchatnet.com","1 lavega.cz","law-region.ru","laylayhome.com","lboiteux.fr","leadsystemnetwork.com","leatherjourney.org","leben-mit-ms.de","lebenzitate.com","legacyrecordings.com","lemimosesportland.it","lengow.com","leos-berolina.de","lernen-top100.de","lesprixducoin.com","levautomacao.com.br","levigxi.com","liblit.com","libsyn.com","lifestylebloggo.de","lighterthanairamerica.com","lighthouseexecutives.com","lightingcontrolsassociation.org","lihebo.com","limasollunaci.com","lindsaysfurniturerc.com","lineamundial.com.ar","linkhoster.com","linkopp.net","linksdepot.net","literatinagyferenc.hu","liuzigu.com","liveinfitness.com","ll2.de","lnkeg.com","logis.im","loqal.no","louisianafresh.com","lovedwell.com","loveformusic.it","l-training.ch","luccasocialandgames.com","luigjes.com","lviv.ua","lzjl.com","m10086.info","mabil.ca","madberry.org","mails2.net","mamaedirce.com.br","mammitzsch.com","maneraprivada.eu","manthanarts.com","manuelromeroifbbpro.com","marianum.eu","marionhansen.de","maripuente.com","martialink.co.uk","masireagahi.com","massotherapieadomicile.ca","masterdesigns.co.uk","maximusart.rs","maxrank.org","mayanrocks.com","mb.ca","mcfc.pl","medanorganik.com","media-pgri.com","mediapointds.com","mediav.com","meetmyshops.com","megadelfi.com","megasun.md","megatona.net","mehmettourism.com","mellow-mushroom.com","memorydropbox.ca","mental-yoga.org","merawatpenyakit.com","merchandising.ru","mesjeuxdefilles.com","metalyzer.com","metarss.com","meta-ua.com","metropolitan-decorating.com","mezatforum.com","mgutm.ru","mhsalumniassoc.org","michaelbrownsuccesssystem.com","michigan.com","microchip.com","midnitemusic.ch","migashco.com","mihokos21grams.com","mikebi.ru","milanuncios.com","militaryhq.com","milujuhovezi.cz","mincultri.ru","minecraftfreeversion.com","minecraftgameonlinefree.net","minidetector.com","mip-eg.com","mix.dj","mjjcommunity.com","m-learn.eu","mmfeist.de","mmorpg-net.net","mmr.ua","mnaidsproject.org","mndsoft.com","mn.us","modalibri.it","modasvet.ru","modthesims.info","moe.ma","montrealgazette.com","morbits.net","morningstar.se","morrissey-solo.com","moteur.ma","motors.co","mountprospect.org","movies-corner.com","movistar.es","mrszinkowsclass.com","msharetips.com","msus.me","mt27.co.id","mtqmexico.com","mulangsari.com","multibodymujer.com","muria.co.id","muzby.net","muzmax.ru","myarcadeplace.com","mycallroom.com","mycapitaltv.com","myf1racing.com","mylittleponygamez.net","mysatoristudio.com","mysnowwhiteteeth.com","mywebstorage.de","myxbox.net","na.by","nadiaemelia.com","nagalanddirectory.com","najvayeghalam.ir","nanapan.net","napavalleyduo.com","nasa.gov","nashi-progulki.ru","nationalcityca.gov","navaraclub-thai.com","nawcc.org","nazwa.pl","nd-graphics.de","ndyz.cn","needtoclick.me","neogaf.com","neska.lt","net.pl","neurostar.com","newmvs88.com","newmvs88.com","newportbeachca.gov","new-potolok.ru","newprotect1.com","newsoft7.ru","newsvine.com","newtechschool.com","nicholecheza.com","nichost.ru","nickymagnummedia.com","nieuwsflitser.nl","nisinetworks.de","no5hair.co.uk","nolbune.net","northparkresidences-booking.com","noticiasabc.com","novonordisk.ch","novonordisk.fi","nowoscimp3.pl","npgfoundation.org","nuevorumbo.net","nukecops.com","nusantarawebsite.com","nutritionforum.com","nytitanwrestling.com","observatoiredescomores.com","offalygates.com","office-kakehashi.com","oldiestation.es","olgamebel.ru","olsonpages.com","olympe.in","omanex.com","omoshiro-news.com","ondeweb.in","on.gt","onlinehome.fr","onlinehome.us","oops.jp","opalubka-center.ru","open-realty.org","opera7.jp","optimumbeton.eu","orain.org","orainyphotography.com","oralpin.com","org.au","org.in","org.mt","org.sv","org.uk","origitea.ru","orijan.com","orionresearch.org","orugacreativa.com","oswik.com","ourcoolvillage.com","outdoornews.com","ozarks.edu","ozerysport.ru","p93.us","paceadvantage.com","padeltraining.com","pakchemical.com","palmantics.com","pandawillforum.com","panduankita.com","paradaanimal.com.br","parcero.net","parc-w.info","pa-s.de","pastelariabusiris.com","pasulukanlokagandasasmita.com","patriciaamaya.com","paulabanks.com","pa.us","pavimentosarquiservi.com","pdtgroup.info","pearsoned.co.uk","pegpropgroup.co.uk","pensiunegorj.ro","percussioneducationonline.com","perfectnakedgirls.com","personcounty.net","petrastdpc.com","phpsns.com","phwattana.com","pijatanstudio.com","pilotinfo.cz","pilulo.us","pingnw.com","pinoysarisarilah.com","pistonbay.com","pivovrazliv.ru","pixnet.net","pixtac.com","plateforme-xgh.com","platingmbh.de","playgungames.net","pleaselandhere.com","pmituban.com","pnpd.co.uk","pobieralnia.org","poetrysplash.com","polressimalungun.com","polynesia.tk","pomoc-zwierzakom.pl","portail2.com","porteno.net","powdertechcorby.co.uk","powerlines.ru","pozinsurance.com","ppcu.org","prazdnichnyymir.ru","premium72.info","productosnaturalesyartesanalesfincachipitlan.com.mx","proficup.ru","profieye.com","profwebcenter.ru","projectavalon.net","projectbodybuilding.com","promoteboard.com","prom.ua","promusichandbook.net","prop2go.mx","prostateimplant.com","p-spa.ru","ptland.jp","puertasdelamarina.com","puertasdelamarina.net","puertaslasabina.com","pungi-cumparaturi.ro","pytkowski-art.com","qaradawi.net","qd-yuanyuan.com","qee.jp","qflny.com","qr.net","qtrace.org","quadrantcenter.com","racbeecroft.com","radiationvibe.com","radioactiva997.com","radioclub.es","railroad-x-forum.com","raul.gallery","rbbs1.net","rcfc.de","reachfld.com","realestateschoolofsc.mobi","redandwhiteproductions.com","redenovatv.com.br","redhawkassociates.mobi","refhius.com","reiat-theater-stetten.ch","renamed-gaming.de","replicawatch-store.com","rerolled.com","revakliev.com","rightkorean.com","rion-service.co.jp","roboguardalarms.com","rockstah.com","rodelclub.li","rodoangeltravel.com","rosaceagroup.org","rotaryinternational.lv","rsclasses.org","rsclassic.us","rtbassociates.com","rtmatic.net","rtwilliams.co.uk","rubenrubio.mx","runte-marsberg.de","ruri2.com","rvlx.us","rv.ua","rwdake.com","sachdochoi.com","sadieberry.tk","saeedpazoki.info","safe.mn","saham2.com","sainttheresemustangs.com","sakura-boo-boo.jp","sales-frontier.com","sanalda1numara.org","sandiegocustommotorcycles.info","sanihon.com","sanpai-web.com","santeck.eu","sassyinfotech.com","scandesigns.dk","scaredsh-tlessthemovie.net","schoolpedagogy.org","schylling.com","sck.dk","scoop.it","scottblairinteriordesign.com","scout24.com","scrapmetaltalk.com","scribd.com","sda-ilijas.ba","searchamateur.com","secretlabtech.com","sedonaaz.gov","seesaawiki.jp","seil.la","sellhaironline.com","semanariolocal.cl","semprainyeccion.com","sendbuttonprofits.com","seoportal.ro","seozeng.com","sepehrcar.com","ser2master.science","seraiki.net","serambibisnis.com","sergiogameplayer.com","serveradvance.ru","servis-autoplus.com","sf311.org","sfdhr.org","sfgovtv.org","sfwater.org","shanasfashions.net","sharenotes.net","sharetheroadsafely.gov","sharkbusinessconnection.com","shark-games.net","shiras.org","shivnee.com","shopatron.com","shopcheck.ch","shopping-tirol.at","shopwiki.es","shorl.com","shortlinki.com","shstezpur.com","shtork.in","sictra.no","siemaco.ch","sigames.com","sigarashow.com","sigarashow.ru","simars.ru","simplehealthnh.com","simpleloveadvice.com","simple-server.com","sinarharapancutterindo.com","sinfoniettapolonia.pl","sites4teachers.com","sjrcenter.org","skelbiu.lt","sketch-bd.com","skypixel.ir","slav-yard.ru","sleepingbeauteez.com","slideshare.net","slutswifes.com","smalapala.com","smarterasp.net","smirajasthan.org","smka.org","smoothiesbeautyclinic.co.uk","smsh.me","snopes.com","snowfactory.com","snuf.it","soccerprofoot.com","socialseolist.com","sofasetc.net","softpart.ru","sogou.com","soporte-movil.com","so-ten.jp","sottel.ru","sourceforge.net","soyanews.info","speckom2.ru","spielberg-double.com","splendidhotel.ru","sportman.by","sptgeotecnia.es","stabx.net","standardminingcompany.com","standrewscricketclub.co.uk","startingmma.com","steamcommunity.com","stepbystep.by","stephenakintayo.com","stm-gamers.com","storemax.com.au","streetfire.net","strictlytuition.com","strongriver.com","stroycom53.ru","suachuamavach.com","sun63.ru","sunsetalgarve.com","supermulticolor.com","svartekunst.no","swrpgnetwork.com","sxsly.com","synantisis.eu","systempardazgil.com","takoora.com","talkreviews.com","talkreviews.com","tanculkovo.sk","taratsidis.gr","taringa.net","taxpolicycenter.org","td-uslovaja.ru","teachipr.com","technewsbd24.com","techyworld.in","teiling.ch","teko-shop.ru","telediez.com","telepolis.pl","teletronltd.com","telugutvtalkies.in","temprana.pl","tenshin-ryu.co.uk","tepozmapa.com","terabytestudio.com","teropongumsu.co","tgcostruzioni.it","tgirltrack.com","thaidogcenter.com","thailandqa.com","thaimeboard.com","thaipinoy.com","theabundancegroup.co","theeradej.com","thefactorygadsden.com","thegioicuanhua.vn","the-horror.com","thenewhot.com","therachelswanfund.org","thesmarterbusiness.com","thewebreport.com","thexrapp.com","thfox.com","thingthingarena32.com","thisislifeschool.com","thisismarilyn.com","threelions.no","threelollies.com","thunderboy.de","thurrockfestival.co.uk","tienganhdeec.com","tinyfi.com","tinyurl.cf","tinyurl.us","tiristor.ru","tistory.com","tnscg.com","tobie.fr","toc.hk","todoalmejorprecio.es","todofierro.com.ar","tok2.com","tokio19.ru","topenk.com","topmodel.it","topmodelspiele.com","torontocomputertech.com","torrevieja.com","totalbrest.com","towerdefense.me","toysrus.com","tppm.by","trainbasketball.info","trainplace.com.au","transeffect.com","travelsdk.com","tribhaktialhusna.com","tribu.red","triport.ru","tropicafarms.in","trovit.com","trucktv.eu","tsbank.ru","tty.nu","tulsa.eu","tumblr.com","turningturning.com","tuskar.by","tut3d.com","tut.su","tz-valeo.com","ucla.edu","udm4.com","uduroc.com","uiucnopants.com","ukksm.ru","ukrdomen.com","ulmf.org","ultra-joy.com","uluv.us","ummulqurodepok.com","underconstructiondayz.co.uk","ungthuphoi.info","unisew.co.uk","uniteldirect.co.uk","universitywebguide.com","uniwearmoda.com","unjubilado.info","unterleider-strassenbau.de","un-wiredtv.com","upr.edu","upstaresclub.com","upupplease.org","urbanexplorationsquad.be","urbanomx.com","url.bz","usasexguide.info","useurl.net","usi.ch","usk.ru","utm.my","uvleddetector.com","v8-rental.com","valacro.eu","vapewiki.com","vasta.in","vegan-victory.de","vegasystems.com","vendesanfrancisco.com.ar","v.gd","villagefloorcovering.biz","viralsections.com","virgendefatima.es","vivicreators.com","vivremerpheecotravel.com","vladit.ru","vlcg.net","voidstar.com","vokr.com","volgomotolom.ru","voloclubfenice.com","volty.com","vsil.org","vurl.us","wall-c.com","wallpapereye.com","wandagaghouse.org","wandern-im-winter.ch","wapic.org","warp2games.com","way2blue.com","wcpss.net","webbyline.com","webcams.is","webcis.com","web-directory.mobi","webgains.com","web.gi","webhostingtalk.com.es","webkinzinsider.com","webmdbook.com","webnow.biz","webproworld.com","webru.biz","websitehome.co.uk","weeklysports.co.uk","wellnesswithmary.com","wemakesites.net","whackyourboner.com","wheresweems.com","whiskeyinkandlace.com","whynotsport.com","wickedskills.com","wikipartido.es","wilforum.com","williamlevygutierrez.com","winfarmer.it",
"wirednewyork.com","wo.lt","womonology.ru","wonosarigek.com","woodgreencompanyltd.com","wshworld.de","wyndia.com","wz.cz","xd03.com","xed.cc","xmagz.com","xn----ctbj0bbmbku.xn--p1ai","xn--h1aehhjhg.tv","xoxo-charm.com","xqno.com","xxfuq.com","yahvlane.com","yatricar.com","yawarperu.com","yawenedu.com","ykuwait.net","youtube.com","youtubeklipindir.com","ypim.com.au","yuctw.com","yunikoo.net","yuntj.com","yz888.cn","zacbird.com","zanettiterrazzo.com","zanox.com","zepyur.am","zhkdesign.com","zhp.pl","zipcodeflea.com","zoohome.ru","zupaa.com","zvonite-darom.ru","360overseas.com","3x.ro","acpasion.net","adelement.com","affordableturnkeywebsites.com","aim4media.com","aippc.net","alternatehistory.com","altervista.org","antichat.net","as-salud.com","automaniasiouxfalls.com","azdeals.co.uk","azfj.org","bathandbodyworks.com","bestbuy.com","bestfilms.eu","bezpaleva.ru","blitwise.com","blogspot.com","blogspot.pl","boholbeefarm.com","botecodoilgo.com.br","braingamesnyc.com","brcdn.com","bycontext.com","byethost12.com","caesaremnostradamus.com","carmonix.com.br","carrom.com","cbslocal.com","chatloungebb.com","cherokeecounty-nc.gov","choicestream.com","chuhal.mn","cliclogix.com","cloudfront.net","cncpunishment.com","coches.net","cohnwolfe.it","colortranny.com","com-central.net","com-claimprize.co","company-target.com","com.vn","com-ytu.co","dessertsbydana.mobi","detikone.com","dodgetech.com.ar","domaincrawler.com","dpclk.com","ducandnhung.com","eab.com","edu.co","edu.pl","edu.tw","eheli.at","elearninggame.com","emporiodomedicamento.com.br","exvagos.com","fastclick.net","fcpfindonesia.org","ferramentaerrico.com","firstgreatexpedition.org","florida-links.de","forexvideofactory.com","forojovenes.com","free.fr","friendsinwar.com","froeschle-design.de","funzoneatlanta.com","goodgamestudios.com","gpm-digital.com","gusrilkenedi.com","hackergames.net","hentaigiant.com","hollisterco.com","hopurls.net","howardforums.com","inkfilling.com","intelliad.de","internationalsexguide.info","ismyblogworking.com","jcdanceco.com","jd.com","jobrapido.com","jobui.com","jogger.pl","johnfoeh.com","kerbalspaceprogram.com","kiev.ua","kingsriverfisheries.org","legalbeagles.info","llow3339.com","lovelytrannys.com","luennemann.org","mayanrocks.com","mbzclan.com","mediaoptout.com","microgames.fr","militaryphotos.net","mohdrafi.com","mostpopularwebsites.net","mulka.net","mypangandaran.com","nazarov.net","ne.jp","nelmax.de","net.br","nihonmura.com","nz-hotrod.com","officedepot.com","openlinksw.com","oraculodenostradamus.com","pageinsider.com","paleodietrecipes.website","panoramio.com","payson.se","pinoyexchange.com","pixies-place.com","planetsuzy.org","pornsticky.com","psykeout.net","puertasdominador.com","quisma.com","rebootwithjoe.com","reedsmith.com","remodelnet.com","researchgate.net","rosegaspar.org","rseramedika.com","rtbserver.com","sab-fm.de","salon.by","sat-sharing.info","schoolhistory.co.nz","sci.io","sensog.com","sfdpw.org","sharethis.com","shpplug.in","smowtion.com","stackadapt.com","stingraybeachinn.com","sunstargames.com","tagsrvcs.com","techkrait.ru","thrixxx.com","tiffanysurabaya.com","todomarino.com","travelzad.com","trophee-roses-des-sables.com","tv3.cat","url2s.nl","usasexguide.info","uw.edu","vipnetservices.com","voluumtrk.com","weavrs.info","webs.com","xingcloud.com","yoreparo.com","zeroent.net","zmievski.org","26l.mobi","acuityplatform.com","altrooz.com","ancestry.com","aomaot.com","appspot.com","blogdrauf.de","blogspot.com.es","ca.us","ccgoldenretriever.com","ciberwatch.es","com.cn","com.co","dotomi.com","edu.ve","etgdta.com","fiuxy.com","futboltk.com","htcmania.com","inthenowweddings.com","kellythomasdesigns.com","ku6.com","markettamer.com","maxlab.ru","mestreafiliados.com","neoshoforums.com","org.tw","org.ua","pardot.com","promotools.biz","taobao.com","tvb.com","wiyaphotos.com","xad.com","zen-cart.com","americanpreppersnetwork.com","appflood.com","apsalar.com","fronthousepictures.com","faffcamp.com","fairytaleglitter.bloggplatsen.se","fannys.bloggplatsen.sefannys.bloggplatsen.se","faq.adsika.com","fedoraforum.org","felicahuggins4.postbit.com",
		"felicidadesemgluten.com.br","fetfreaks.co.uk","fiftytb.com","filestream.org","firewall.lv","firmstyle.net","firsturl.de","fisioterapi.univrab.ac.id","fitness-plans-for-women-florence.com",
		"flash.zeidanphy.com","floraindah.web44.net","florenew72243.postbit.com","foro.kumbiaphp.com","foro.libertaddigital.tv","foro.lost-wow.info","foros.arquinauta.com","foro.seprin.com",
		"foros.expansion.com","fortworthtms.mobi","forum2.unitrends.com","forum.bomoo.com","forum.cs1cafe.com","forum.debatarian.com","forum.faak.ru","forum.flightradar24.com","forum.garpy.info",
		"forum.heismarried.com","forum.ionitcom.ru","forum.jowood.com","forum.keypublishing.co.uk","forum.mennigmann.com","forum.n-sk.info","forum.oqoasis.com","forum.praxisbase.com",
		"forums.allaboutjazz.com","forums.eagle.ru","forums.loquax.co.uk","forums.mydigitallife.info","forums.naughty-seduction.net","forums.qlshifi.com","forums.sagetv.com","forums.thepaceline.net",
		"forums.wtfda.org","forum.t-tapp.com","forum.vyos.net","forum.zohur14.com","foto-biysk.ru",
"wap.xxmmhh.net","jnpt.jp","pinterest.com","kaiyunholding.com","bernco.gov","cathedralcity.gov","miguelarino.com","dustinstockton.com","wilbooks-literacy-partners.com",
"majavidmar.com","telesentinel.com","ilcerchiomagico.net","gsselular.com","u39414.netangels.ru","abcworshiparts.org","brainboost.tv","cipo.cl","janemcqueen.com",
"thefullyield.com","novotyr.edu22.info","wiki.ustea.org","shufflespot.webcrow.jp","tennisgrandstand.com","to-bi.jp","tikiplay.com","club.thairentacar.com",
"studio.chance-magazine.com","srilankanbesttravels.com","mffcu.org","petrotechgroups.com","smpdh.com","tracker.affiliate.media.net","fredericlaprise.com","counter.arabamoto.com",
		"uasdan.com","tku.edu.tw","honeymoonbroadway.com","urlshotgun.zendesk.com","andersonlanham6.bligoo.com","protect.downloadiz2.com","chicagorehab.net","pa-kudus.go.id","studio-one-touch.ru","ldbs.foxdevel.com",
		"kireenko.by","benjaminbos.nl","tragaperras777.com","weightlosstipstv.com","pvt.prv.pl","damle.org","mccleto.com","hosei-im.jp","juigames.com","teknisk-brevkasse.dk",
		"fastsync.de","ironmanhawaii.de","8game.ir","guabob.com","donorcall.com","outpostbravo.com","g-javierortega.newsvine.com","keygroupinternational.com","svendemeyere.write2me.nl",
		"hksnv.fksnv.sk","cityprepsports.com","bjhdjj.com.cn","chiefhudson.com","southseattlecrossfit.com","bazisun.ir","office-board.net","onlinesocial.ru","memphis-tn.com","guestbook.redravenllc.com",
		"foodspotting.com","middelhavetsperle.com","harrietsellingblog.com","visioncenterslv.com","altai.aif.ru","cqumzh.cn","rsud.wonosobokab.go.id","dynamod.com","simplebrunchideas.com",
		"knopa-lepa.ru","ksaemarket.com","cqumzh.cn","gburugburuwins.org","agimato.crystalstar.me","ginki.it","findyourway.in","serralheriaght.com.br","gadgetvlog.com","gwearn.com","gamerstvspot.com","wikiova.com",
		"eu.purefishing.com","lankaeuro.info","atrophythemovie.com","bildergeburtstag.com","cts.businesswire.com","bkxiaoyu.com","en.eelink.com.cn""bmu.fr","rebelmouse.com","lulle.sakura.ne.jp",
		"pa-kudus.go.id","studio-one-touch.ru","kireenko.by","benjaminbos.nl","tragaperras777.com",
		"weightlosstipstv.com","pvt.prv.pl","damle.org","mundoambiente.com.br","trustinsurance.co.uk","u39414.netangels.ru",
		"juigames.com","fotocasa.es","blacdetroit.com","consumeractiongroup.co.uk","romwe.com","bbs.whu.edu.cn","productads.hlserve.com","tudocelular.com","apps.lonestar.edu",
		"crossfit128.com","org.idv.tw","northdallaseo.com","thechangesource.com","sabceducation.com","cafekazan.com","jogos.connectvr.com","dudyeffendy.com","flat.ciseleur.com",
		"c4mountainbike.com","lechfeld-lamas-alpakas.de","tssj.cl","cpoar.org","biocenterortodoncia.com","uzin.com.ua","geologopatelli.it","mobimeasure.co.za","mobyleapps.com","tipseri.org",
		"mini-juegos.net","grapplingtournaments.com","hackermeetup.com","ebooks.addall.com","external.worldbankimflib.org","cathedralcity.gov","cops.usdoj.gov","bekamsehat.com",
		"cqumzh.cn","altai.aif.ru","polytrauma.va.gov","fateh.sikhnet.com","legix.pt","aif.ua","louisiana.gov","expert.ru","cqumzh.cn","gettyimages.fr","tinyurl.com","altai.aif.ru",
		"polytrauma.va.gov","ferra.ru","big5.shanghai.gov.cn", "demonoid.pw","res-x.com","kartes.lv","estetica-design-forum.com","bauskasdzive.diena.lv",
		"unimedfesp.coop.br","flix360.com","254a.com","ksmobile.net","cnt.my","mmstat.com","gfy.com","flixcar.com","ekspedisicepat.com", "turk-bh.ir","alenty.com","gandhi.com.mx",
		"exelator.com","fitfuel365.com","popjustice.com","inverly.com", "badoocdn.com", "contextweb", "technoratimedia.com","youku.com","autoscout24.com","forumodua.com",
"fronthousepictures.com","frozenfood.ru","dineroforo.com"].any? {|word| host.downcase.include?(word)}
		if (@filters.is_inInria_PriceTagList?(host,keyVal) or @filters.has_PriceKeyword?(keyVal)) 		# Check for Keywords and if there aren't any make ad-hoc heuristic check
			return false if isItDuplicate?(row)
			priceTag=keyVal[0]
			paramVal=keyVal[1]
			type=""
			priceVal,enc=@convert.calcPriceValue(paramVal,isAdCat)
			return false if priceVal==nil
			done=-1
			if enc
				type="numeric"
				return false if priceVal.to_f<0
				return false if priceVal.infinite?
			else
				type="encrypted"
				alfa,digit=Utilities.digitAlfa(paramVal)
				return false if (alfa<2 or digit<2) or priceVal.size<15
			end
			if @database!=nil
				id=Digest::SHA256.hexdigest (row.values.join("|")+priceTag+"|"+priceVal.to_s+"|"+type)
				time=row['tmstp']
				dsp,ssp,adx,publisher,adSize,carrier,adPosition=@filters.lookForRTBentitiesAndSize(row['url'],domainStr)
				interest,pubPopularity=@convert.analyzePublisher(publisher)
				if interest!=-1
					temp=Hash[interest.sort_by{|k,v| k}].to_s
					interest=temp.gsub(/[{}]/,"")
				end
				typeOfDSP=-1
				if dsp==nil or dsp==-1
					dsp=-1
				else
					typeOfDSP=@convert.advertiserType(dsp) 
				end
				adx=-1 if adx==nil
				ssp=-1 if ssp==nil
				publisher=-1 if publisher==nil
				upToKnowCM=@trace.users[@curUser].csync.size
				location=@convert.getGeoLocation(row['uIP'])
				location=-1 if location==nil 
				tod,day=@convert.getTod(time)
				params=[type,time,domainStr,priceTag,priceVal, row['dataSz'].to_i, upToKnowCM, numOfparams, adSize, carrier, adPosition,location,tod,day,publisher,interest,pubPopularity,row['IPport'],ssp,dsp,typeOfDSP,adx,row['mob'],row['dev'],row['browser'],https,row['url'],id]
				done=@database.insert(@defines.tables['priceTable'],params)
			end
			if @database==nil or done>-1
				if enc
					@trace.users[@curUser].numericPrices.push(priceVal)
					@trace.numericPrices+=1
				else
					@trace.users[@curUser].hashedPrices.push(priceVal)
					@trace.hashedPrices+=1
				end
			end
			return true
		end
		return false
    end

    def detectImpressions(url,row)     	#Impression term in path
        if @filters.is_Impression?(url[0])
			if @options['tablesDB'][@defines.tables["impTable"].keys.first]
				Utilities.printRowToDB(row,@database,@defines.tables['impTable'],nil)				
		    	@trace.users[@curUser].imp.push(row)
			end
			@trace.totalImps+=1
			return true
        end
		return false
    end

	def checkForRTB(row,url,publisher,adCat)
     	return 0,false if (url.last==nil)
		isAd=false
        fields=url.last.split('&')
		numOfPrices=0
		https=-1
		https=url.first.split(":").last if url.first.include?(":")
        for field in fields do
            keyVal=field.split("=")
            if(not @filters.is_GarbageOrEmpty?(keyVal)) and not url.first.include? "google" and not url.first.include? "eltenedor.es" and not url.first.include? "gosquared.com" and not url.first.include? "yaencontre.com" and not url.first.include? "bmw.es" and not url.first.include? "bing.com" and not url.first.include? "onswingers.com" and not url.first.include? "tusclasesparticulares.com" and not url.first.include? "ucm.es" and not url.first.include? "noticias3d.com" and not url.first.include? "loopme.me" and not url.first.include? "amap.com" and not url.first.include? "anyclip.com" and not url.first.include? "promorakuten.es" and not url.first.include? "scmspain.com" and not url.first.include? "shoppingshadow.com"
				#isAd=true if(@filters.is_Ad_param?(keyVal))
				if @options['tablesDB'][@defines.tables["priceTable"].keys.first]
					if detectPrice(row,keyVal,numOfPrices,fields.length,publisher,(adCat or isAd),https)
						numOfPrices+=1
					#	Utilities.warning ("Price Detected in Beacon\n"+row['url']) if @isBeacon
						isAd=true
					end
				end
			end
		end
		return fields,isAd
	end
			
	def beaconSave(url,row)         #findBeacons
		@isBeacon=true
		urlStr=url.split("%").first.split(";").first		
		temp=urlStr.split("/")	   #beacon type
		words=temp.size
		slashes=urlStr.count("/")
		last=temp[temp.size-1]
        temp=last.split(".")
		if (temp.size==1 or words==slashes)
			type="other"
        else
			last=temp[temp.size-1]
        	type=last
		end
		@trace.party3rd["Beacons"]+=1
		tmpstp=row['tmstp'];u=row['url']
		id=Digest::SHA256.hexdigest (row.values.join("|"))
		@trace.beacons.push([tmpstp,row['IPport'],u,type,row['mob'],row['dev'],row['browser'],id])
		collector("Beacons",row)
	end

	def ad_detected(row,noOfparam,url)
        @trace.users[@curUser].ads.push(row)
		@trace.adSize.push(row['dataSz'].to_i)
		collectAdvertiser(row)
   #     @trace.users[@curUser].adNumOfParams.push(noOfparam.to_i)
		@trace.adNumOfParams.push(noOfparam.to_i)
		if(row['mob']!=-1)
			@trace.numOfMobileAds+=1
		end
	end

	def collectAdvertiser(row)
		if row!=nil and @options['tablesDB'][@defines.tables["advertiserTable"].keys.first]
			host=row['host']
			if @trace.advertisers[host]==nil
				@trace.advertisers[host]=Advertiser.new
				@trace.advertisers[host].durPerReq=Array.new
				@trace.advertisers[host].sizePerReq=Array.new
			end
			#@trace.advertisers[host].totalReqs+=1
			@trace.advertisers[host].reqsPerUser[@curUser]+=1
			@trace.advertisers[host].durPerReq.push(row['dur'].to_i)
			@trace.advertisers[host].sizePerReq.push(row['dataSz'].to_i)
			@trace.advertisers[host].type=@convert.advertiserType(host)
		end
	end
end
