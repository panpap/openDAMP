load 'define.rb'
load 'core.rb'
require 'digest/sha1'

class Operations
	@@loadedRows=nil

	def initialize(filename)
		@defines=Defines.new(filename)
		@func=Core.new(@defines,false)
	end

	def loadFile()
		puts "> Loading Trace..."
		@@loadedRows=@func.loadRows(@defines.traceFile)
		puts "\t"+@@loadedRows.size.to_s+" requests have been loaded successfully!"
	end

    def separate
		atts=@@loadedRows[0].keys
		f=Hash.new
		atts.each{|a| f[a]=File.new(@defines.dirs['dataDir']+a,'w')}
        for row in @@loadedRows do
            atts.each{|att| f[att].puts row[att] if att!='url'}
			Utilities.separateTimelineEvents(row,@defines.dirs['userDir']+row['IPport'])
   		end
		atts.each{|a| Utilities.countInstances(@defines.dirs['dataDir']+a); f[a].close}
	end

	def makeTimelines(sec,path)
		@func.window=sec.to_i*1000 #store in msec
		@func.cwd=path
		cwd=path
		path=cwd+@defines.userDir
		entries=Dir.entries(path) rescue entries=Array.new
		if entries.size > 3 # DIRECTORY EXISTS AND IS NOT EMPTY
			puts "> Using existing per user files..."
			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
			@func.readTimelines(entries)
		else
			Dir.mkdir path unless File.exists?(path)
			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
			puts "> There is not any existing user files. Separating timeline events per user..."
			# Post Timeline Events Separation (per user)
			if not File.exists? cwd+@defines.dataDir
				puts "Error: No file exists please run again with -s option"
			else
				@func.createTimelines()
			end
		end
	end

  	def stripURL      
		puts "> Stripping parameters, detecting and classifying Third-Party content..."
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

	def quickParse()
		puts "> Quick trace parsing..."
		adsTypes=nil
		for r in @@loadedRows do
			@func.parseRequest(r,true)
		end
		trace=@func.getTrace
	end

#------------------------------------------------------------------------



	private


	def analysisResults(trace)
		fw=File.new(@defines.files['parseResults'],'w')
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
        Utilities.countInstances(@defines.files['beaconT'])
		@func.perUserAnalysis()
		system("sort "+@defines.files['priceTagsFile']+" | uniq >"+@defines.files['priceTagsFile']+".csv")
		system("rm -f "+@defines.files['priceTagsFile'])
		results=Utilities.results_toString(trace,prices,numericPrices)
		fw.puts results
		puts results
		fd=File.new(@defines.files['devices'],'w')
		trace.devs.each{|dev| fd.puts dev}
		fd.close
		fsz=File.new(@defines.files['size3rdFile'],'w')
		trace.sizes.each{|sz| fsz.puts sz}
		fsz.close
		fw.close
		#PLOTING CDFs
		puts "Creating CDFs..."
		puts "TODO... Devices, Prices, NumOfParameters,popular ad-related hosts,3rdParty Size"
		@func.close
	end
end

