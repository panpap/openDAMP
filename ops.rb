require 'digest/sha1'
require 'define'
require 'utilities'
require 'core'

#IP_Port--UserIP--URL--UserAgent--Host--Timestamp--ResponseCode--ContentLength--DeliveredData--Duration--HitOrMiss

class Operations
	@@func=nil
	@@utils=nil
	@@totalNumofRows=-1
	
  	def initialize(*args)
		@@func=Core.new
		@@utils=Utilities.new
	end

	def load(filename)
		puts "> Creating Directories..."
		Dir.mkdir @@dataDir unless File.exists?(@@dataDir)
                Dir.mkdir @@adsDir unless File.exists?(@@adsDir)
		puts "> Loading Trace..."
		@@totalNumofRows=@@func.loadTrace(filename)
		puts "\t"+@@totalNumofRows.to_s+" have been loaded successfully!"
	end

        def separate()
		rows=@@func.getRows
                for key in rows[0].keys() do
                        @@func.separateField(key,@@dataDir)
       		end
	end

	def clearAll()
                system('rm -rf '+@@dataDir)
                system('rm -rf '+@@adsDir)
		system('rm -f *.out')
	end

  	def stripURL()      
		puts "> Stripping parameters, detecting and classifying Third-Party content..."
		adsTypes=nil
		rows=@@func.getRows
		fi,fa,fl,fp,fn,fd1,fb,fm,fz,fd2=@@utils.openFiles
		for r in rows do
			@@func.filterAds(r,fa,fl,fi,fp,fn,fd1,fb,fz,fd2)
			if r['url'].split("?")[0].include? "mopub.com"
				@@utils.printRow(r,fm)
			end
		end
		fm.close;fp.close;fb.close;fz.close;fi.close; fa.close; fl.close;fn.close;fd1.close;fd2.close
		parseResults()
	end

	def parseResults
		puts "> Calculating Statistics about detected ads..."

		#IMPRESSIONS
		imps_cnt=@@func.getImp_cnt
	
		#LATENCY
		lat=@@func.getLatency
		avgL=lat.inject{ |sum, el| sum + el }.to_f / lat.size
	#	@@utils.makeDistrib_LaPr(@@adsDir)

		# 3rd PARTY CONTENT
		sizes3rd=@@func.getSizes
		sumSize=sizes3rd.inject{ |sum, el| sum + el}
		avgSize=sumSize.to_f / sizes3rd.size

		#DETECTED ADS
		totalAds,adsTypes, filterTypes,adBeacon=@@func.getAdResults
		min,max,avg,median=@@func.analyzeAds(@@adsDir)

		#PRICES
                prices=@@func.getPrices
                numericPrices=Array.new
                for p in prices do
                        if @@utils.is_float?(p)
                                numericPrices.push(p)
                        end
                end
                avgP=numericPrices.inject{ |sum, el| sum + el }.to_f / numericPrices.size

		#BEACONS
                beacons,beaconType=@@func.getBeacons
                totalBeacons=beacons.size
                f=File.new(@@adsDir+@@beaconT,'w')
                for b in beaconType do
                        f.puts b
                end
                f.close
                @@utils.countInstances(@@adsDir,@@beaconT)

		#PRINTING RESULTS		
		puts "Printing Results...\n--------"
		puts "Traffic from  mobile devices: "+@@func.getMobDevs.to_s+"/"+@@totalNumofRows.to_s
		puts "3rd Party content detected:\n"
		filterTypes.each { |key,value| print key+" => "+value.to_s+" "}
		puts "\nSize of the unnecessary 3rd Party content (i.e. Adverising+Analytics+Social)\nTotal: "+sumSize.to_s+" Bytes - Average: "+avgSize.to_s+" Bytes"
		puts "Total Ads-related requests found: "+totalAds.to_s+"/"+@@totalNumofRows.to_s
		puts "Ad-related traffic using mobile devices: "+adsTypes["mob"].to_s+"/"+totalAds.to_s
		puts "Number of parameters:\nmax => "+max.to_s+" min=>"+min.to_s+" avg=>"+avg.to_s+" median=>"+median.to_s
                puts "Price tags found: "+prices.length.to_s
                puts numericPrices.size.to_s+"/"+prices.size.to_s+" are actually numeric values"
                puts "Average price "+avgP.to_s

		puts "Beacons found: "+totalBeacons.to_s+"\nAds-related beacons: "+adBeacon.to_s+"/"+totalBeacons.to_s
	        puts "Impressions detected "+imps_cnt.to_s
	        puts "Average latency "+avgL.to_s
		puts adsTypes
	
		#PLOTING CDFs
		puts "Creating CDFs..."
		puts "TODO... Devices, Prices, NumOfParameters,popular ad-related hosts,3rdParty Size"
	end

	def findStrInRows(str,printable)
		count=0
		found=Array.new
		puts "Locating String..."
		rows=@@func.getRows
		for r in rows do
			for val in r.values do
				if val.include? str
					count+=1
					if(printable)
						url=r['url'].split('?')
						@@utils.printRow(r,STDOUT)
					end
					found.push(r)					
					break
				end
			end
		end 
		if(printable)
			puts count.to_s+" Results were found!"
		end
		return found
	end

	def getPublishers	

	end
end

