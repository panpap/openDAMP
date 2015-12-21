require 'define'
require 'core'
require 'digest/sha1'

class Operations
	@@loadedRows=nil

	def initialize(filename)
		@defines=Defines.new(filename)
		@func=Core.new(@defines)		
	end

	def loadFile()
		puts "> Loading Trace..."
		@@loadedRows=@func.loadRows(@defines.traceFile)
		puts "\t"+@@loadedRows.size.to_s+" requests have been loaded successfully!"
	end

    def separate
        for row in @@loadedRows do
            @func.separateField(row)
   		end
	end

	def makeTimelines(sec,path)
		@func.window=sec
		@func.cwd=path
		cwd=path
		path=cwd+@defines.userDir
		entries=Dir.entries( path+@defines.tmln_path) rescue entries=Array.new
		if entries.size > 0 # DIRECTORY EXISTS AND IS NOT EMPTY
			puts " > Using existing per user files..."
			@func.readTimelines(entries)
		else
			Dir.mkdir path unless File.exists?(path)
			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
			puts " > There is not any existing user files. Separating timeline events per user..."
			# Post Timeline Events Separation (per user)
			if not File.exists? cwd+@defines.dataDir
				puts "No file exists please run again with -s option"
			else
				@func.createTimelines()
			end
		end
	end

  	def stripURL      
		puts "> Stripping parameters, detecting and classifying Third-Party content..."
		adsTypes=nil
		for r in @@loadedRows do
			@func.parseRequest(r)
		end
		trace=@func.getTrace
		analysisResults(trace)
	end

	def findStrInRows(str,printable)
		count=0
		found=Array.new
		puts "Locating String..."
		rows=@func.getRows
		for r in rows do
			for val in r.values do
				if val.include? str
					count+=1
					if(printable)
						url=r['url'].split('?')
						Utilities.printRow(r,STDOUT)
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



#------------------------------------------------------------------------



	private


	def analysisResults(trace)
		fw=File.new(@defines.parseResults,'w')
		puts "> Calculating Statistics about detected ads..."
		#LATENCY
	#	lat=@func.getLatency
	#	avgL=lat.inject{ |sum, el| sum + el }.to_f / lat.size
	#	Utilities.makeDistrib_LaPr(@@adsDir)
		#PRICES
        numericPrices=Array.new
		prices=trace.detectedPrices
        for p in prices do
            if Utilities.is_float?(p)
                numericPrices.push(p.to_f)
            end
        end
        Utilities.countInstances(@defines.beaconT)
		@func.perUserAnalysis()
		system("sort "+@defines.priceTagsFile+" | uniq >"+@defines.priceTagsFile+".csv")
		system("rm -f "+@defines.priceTagsFile)
		results=Utilities.results_toString(trace,prices,numericPrices)
		fw.puts results
		puts results
		fw.close
		#PLOTING CDFs
		puts "Creating CDFs..."
		puts "TODO... Devices, Prices, NumOfParameters,popular ad-related hosts,3rdParty Size"
		@func.close
	end
end

