require 'filters'

class Core
	@@mobDev=0
        @@adDevice=Array.new
        @@isBeacon=false
	@@imp=Array.new
	@@rows=Array.new
	@@utils=Utilities.new
	@@filters=Filters.new
	@@dPrices=Array.new
	@@ads=Array.new
	@@paramNum=Array.new
        @@beacons=Array.new
        @@adBeacon=0
        @@beaconType=Array.new
	@@device=Array.new
	@@adFilter=nil
	@@sizes3rd=Array.new
        @@adsType={"adInUrl"=>0,"params"=>0,"imp"=>0,"mob"=>0}
        @@filterType={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0}

	def getPrices
		return @@dPrices
	end

	def getMobDevs
		return @@mobDev
	end

	def getSizes	
		return @@sizes3rd
	end

	def getRows
		return @@rows
	end

	def getBeacons
		return @@beacons, @@beaconType
	end

	def getImp_cnt
		return @@imp.length
	end

	def getLatency	
		return @@filters.getLatency
	end

	def getAdResults
		return @@ads.size, @@adsType, @@filterType, @@adBeacon
	end

        def loadTrace(filename)
                f=File.new(filename,'r')
                line=f.gets     #get rid of headers
                while(line=f.gets)
                        h = Hash.new(-1)
                        part=line.chop.split("\t")
                        h['IPport']=part[0]
                        h['uIP']=part[1]
                        h['url']=part[2]
                        h['ua']=part[3]
                        h['host']=part[4]
                        h['tmstp']=part[5]
                        h['status']=part[6]
                        h['length']=part[7]
                        h['dataSz']=part[8]
                        h['dur']=part[9]
                        h['HtorM']=part[10]
                        @@rows.push(h)
                end
                f.close
		@@adFilter=@@filters.loadExternalFilter
                return @@rows.length
        end

        def separateField(att,dir);
                puts "> Separate files and calculate instances for "+att
                fw=File.new(dir+att,'w')
                for r in @@rows do
                        fw.puts r[att]
                end
		@@utils.countInstances(dir,att)
                fw.close
        end

        def detectPrice(keyVal,fa);          	# Detect possible price in parameters and returns URL Parameters in String 
		if (@@filters.has_PriceKeyword?(keyVal)) 		# Check for Keywords and if there aren't any make ad-hoc heuristic check
                  	fa.puts keyVal[0]+"\t"+keyVal[1]
			@@dPrices.push(keyVal[1])
			return true
		#else
		# 	HEURISTIC 1: all prices seem to be float and <4 chars.
		# 	HEURISTIC 2: price will definately be 0<price
		#	if (keyVal[1].length < 5 and @@utils.is_float?(keyVal[1]) and keyVal[1].to_f>0) 
		#		fw=File.new('possible_prices.out','a')
		#      		fw.puts "> "+keyVal[0]+" => "+keyVal[1]
		#		fw.close
		#	end
		end
		return false
        end

        def detectImpressions(url,row,fw);     	#Impression term in path
                if @@filters.is_Impression?(url[0])
			@@utils.printRow(row,fw)
                        @@imp.push(row)
			return true
                end
		return false
        end

	def analyzeAds(dir)        		#Analyze parameters
		@@utils.countInstances(dir,@@paramsNum)
		@@utils.countInstances(dir,@@devices)
		@@utils.countInstances(dir,@@size3rdFile)
		puts @@paramNum.size.to_s+" "+@@ads.size.to_s
		avg=@@paramNum.inject{ |s, el| s + el }.to_f / @@paramNum.size
		median=@@utils.median(@@paramNum)
		return @@paramNum.min,@@paramNum.max,avg,median
	end

	def checkParams(row,url,fp,fb)
	     	if (url[1]==nil)
             		return 0,false
        	end
		isAd=false
                fields=url[1].split('&')
                for field in fields do
                        keyVal=field.split("=")
                        if(not @@filters.is_GarbageOrEmpty?(keyVal))
				if(@@filters.is_Beacon_param?(keyVal) and not @@isBeacon)
					beaconSave(url[0],row,fb)
				end
				if(detectPrice(keyVal,fp))
					isAd=true
				end
				if(@@filters.is_Ad_param?(keyVal))
					isAd=true
				end
			end
		end
		return fields.length,isAd
	end
			
	def beaconSave(url,row,fb)         #findBeacons
		@@isBeacon=true
        	@@beacons.push(row)
		@@utils.printRow(row,fb)
		urlStr=url.split("%")[0].split(";")[0]
		temp=urlStr.split("/")	   #beacon type
		words=temp.size
		slashes=urlStr.count("/")
		last=temp[temp.size-1]
                temp=last.split(".")
		if (temp.size==1 or words==slashes)
			@@beaconType.push("other")
                else
			last=temp[temp.size-1]
                	@@beaconType.push(last)
		end
	end

	def beaconImprParamCkeck(url,row,fi,fb,fp) 
                @@isBeacon=false
		isAd=-1
                if (@@filters.is_Beacon?(url[0],url[1]))  		#findBeacon in URL
                        isAd=0
                        beaconSave(url[0],row,fb)
                end
                paramNum, result=checkParams(row,url,fp,fb)             #find ads
                if(result)
                        isAd=1
                        @@adsType['params']+=1
                end
                if(detectImpressions(url,row,fi))
                        isAd=1
                        @@adsType["imp"]+=1
                end
		return isAd,paramNum
	end

	def filterAds(row,fw,fl,fi,fp,fn,fd1,fd2,fb,fz)
		url=row['url'].split("?")
		host=row['host']

		#CHECK IF ITS MOBILE USER
		mob,dev=@@filters.is_MobileType?(row)   # check the device type of the request
		if mob
			@@mobDev+=1
		end
                @@device.push(dev)
                fd1.puts dev

		#FILTER ROW
		isPorI,noOfparam=beaconImprParamCkeck(url,row,fi,fb,fp)
		iaAdinURL=false
		type3rd=@@filters.is_Ad?(url[0],host,@@adFilter)
                if(type3rd!=nil)
                        @@adsType["adInUrl"]+=1
                        @@filterType[type3rd]+=1
			if not type3rd.eql? "Content"
				if type3rd.eql? "Advertising"
					isAdinURL=true
				end
				#CALCULATE SIZE
				sz=row['length']
				fz.puts sz
				@@sizes3rd.push(sz.to_i)
			end
                end
		if(isAdinURL or isPorI>0)
	#		puts row['url']+"\n"+@@adsType.to_s+" "+@@dPrices.size.to_s+" $"+noOfparam.to_s
                        @@ads.push(row)
                        @@paramNum.push(noOfparam)
			fn.puts noOfparam
			if (@@isBeacon)			#is it ad-related Beacon?
				@@adBeacon+=1
				@@isBeacon=false
			end
			if(mob)
				@@adsType["mob"]+=1
			end
			@@adDevice.push(dev)
			fd2.puts(dev)
                        @@utils.printStrippedURL(url,fw)
		elsif(not @@isBeacon and type3rd==nil)	#no beacon||no imp||no third party => leftovers
			@@utils.printStrippedURL(url,fl)
		else
			#Analytics/Social/Beacons do nothing
		end
	end
end
