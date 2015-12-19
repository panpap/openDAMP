require 'define'
require 'utilities'
require 'core'
require 'digest/sha1'

class Operations
	@@func=nil
	@@loadedRows=nil

	def initialize(filename)
		@@func=Core.new	
		if filename==nil
			puts "Warning: Using pre-defined input file..."			
		else
			if File.exist?(filename)
				@@traceFile=filename
			else
				abort("Error: Input file <"+filename+"> could not be found!")
			end
		end
	end

	def loadFile()
		puts "> Loading Trace..."
		@@loadedRows=@@func.loadRows(@@traceFile)
		puts "\t"+@@loadedRows.size.to_s+" requests have been loaded successfully!"
	end

    def separate
		Dir.mkdir @@dataDir unless File.exists?(@@dataDir)
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
		analysisResults(trace)
	end

	def analysisResults(trace)
		fw=File.new(@@parseResults,'w')
		puts "> Calculating Statistics about detected ads..."

		#LATENCY
	#	lat=@@func.getLatency
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

        Utilities.countInstances(@@beaconT)
		@@func.perUserAnalysis()
		system("sort "+@@priceTagsFile+" | uniq >"+@@priceTagsFile+".csv")
		system("rm -f "+@@priceTagsFile)
		results=results_toString(trace,prices,numericPrices)
		fw.puts results
		puts results
		fw.close
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
end

