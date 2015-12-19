require 'define'
require 'utilities'
require 'core'
require 'digest/sha1'

class Operations
	@@func=nil
	@@loadedRows=nil
	@@utils=Utilities.new

	def loadFile(filename)
		@@func=Core.new
		puts "> Loading Trace..."
		if filename==nil
			puts "Warning: Using pre-defined input file..."
			@@loadedRows=@@func.loadRows(@@traceFile)
		else
			if File.exist?(filename)
				@@loadedRows=@@func.loadRows(filename)
			else
				abort("Error: Input file could not be found!")
			end
		end
		puts "\t"+@@loadedRows.size.to_s+" requests have been loaded successfully!"
	end

    def separate
        for key in @@loadedRows[0].keys() do
            @@func.separateField(key)
   		end
	end

	def clearAll
        system('rm -rf '+@@dataDir)
        system('rm -rf '+@@adsDir)
		system('rm -f *.out')
	end

  	def stripURL      
		puts "> Stripping parameters, detecting and classifying Third-Party content..."
		adsTypes=nil
		for r in @@loadedRows do
			@@func.parseRequest(r)
		end
		trace=@@func.getTrace
		parseResults(trace)
	end

	def parseResults(trace)
		puts "> Calculating Statistics about detected ads..."
		totalNumofRows=trace.rows.size		
		paramsStats,sizeStats=trace.analyzeTotalAds
		#LATENCY
	#	lat=@@func.getLatency
	#	avgL=lat.inject{ |sum, el| sum + el }.to_f / lat.size
	#	@@utils.makeDistrib_LaPr(@@adsDir)

		#DETECTED ADS
	#	totalAds,adsTypes,filterTypes,adBeacon=@@func.getAdResults

		#PRICES
        numericPrices=Array.new
		prices=trace.detectedPrices
        for p in prices do
            if @@utils.is_float?(p)
                numericPrices.push(p.to_f)
            end
        end
		pricesStats=@@utils.makeStats(numericPrices)
        @@utils.countInstances(@@beaconT)

		#PRINTING RESULTS		
		puts "Printing Results...\nTRACE STATS\n------------"
		puts "Total users in trace: "+trace.users.size.to_s
		puts "Traffic from  mobile devices: "+trace.mobDev.to_s+"/"+totalNumofRows.to_s
		puts "3rd Party content detected:"
		puts "Advertising => "+trace.party3rd['Advertising'].to_s+" Analytics => "+trace.party3rd['Analytics'].to_s+" Social => "+trace.party3rd['Social'].to_s+" Content => "+trace.party3rd['Content'].to_s+" Beacons => "+trace.party3rd['totalBeacons'].to_s+" Other => "+trace.party3rd['Other'].to_s
		puts "\nSize of the unnecessary 3rd Party content (i.e. Adverising+Analytics+Social)\nTotal: "+sizeStats['sum'].to_s+" Bytes - Average: "+sizeStats['avg'].to_s+" Bytes"
		puts "Total Number of rows = "+(trace.party3rd['Advertising']+trace.party3rd['Analytics']+trace.party3rd['Social']+trace.party3rd['totalBeacons']+trace.party3rd['Content']+trace.party3rd['Other']-trace.totalAdBeacons).to_s
		puts "Total Ads-related requests found: "+trace.party3rd['Advertising'].to_s+"/"+totalNumofRows.to_s
		puts "Ad-related traffic using mobile devices: "+trace.numOfMobileAds.to_s+"/"+trace.party3rd['Advertising'].to_s
		puts "Number of parameters:\nmax => "+paramsStats['max'].to_s+" min=>"+paramsStats['min'].to_s+" avg=>"+paramsStats['avg'].to_s
        puts "Price tags found: "+prices.length.to_s
        puts numericPrices.size.to_s+"/"+prices.size.to_s+" are actually numeric values"
        puts "Average price "+pricesStats['avg'].to_s

		puts "Beacons found: "+trace.party3rd['totalBeacons'].to_s+"\nAds-related beacons: "+trace.totalAdBeacons.to_s+"/"+trace.party3rd['totalBeacons'].to_s
        puts "Impressions detected "+trace.totalImps.to_s
#        puts "Average latency "+avgL.to_s
		system("sort "+@@priceTagsFile+" | uniq >"+@@priceTagsFile+".csv")
		system("rm -f "+@@priceTagsFile)
		puts "PER USER STATS"
		@@func.perUserAnalysis()
		puts "TODO"
	#	puts adsTypes
	
		#PLOTING CDFs
		puts "Creating CDFs..."
		puts "TODO... Devices, Prices, NumOfParameters,popular ad-related hosts,3rdParty Size"
		@@func.close
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
end

