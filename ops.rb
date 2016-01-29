load 'define.rb'
load 'core.rb'
load 'plotter.rb'
require 'digest/sha1'

class Operations
	
	def initialize(filename)
		@defines=Defines.new(filename)
		@options=Utilities.loadOptions(@defines.files['configFile'])
		@func=Core.new(@defines,@options)
		total1=""
		IO.popen("sort "+@defines.traceFile+" | uniq | wc -l") { |io| total1=io.gets.split(" ")[0] }
puts total1
		total2=""
puts total2
		IO.popen("wc -l "+@defines.traceFile) { |io| total2=io.gets.split(" ")[0] }
		if (total2.to_i-total1.to_i)>0
			Utilities.warning(total+" dublicates were found in the trace")  
		end
	end

	def dispatcher(function,str)	
if function==0
	puts "TODO"
	return
end
		@func.makeDirsFiles
		puts "> Loading Trace... "+@defines.traceFile
		count=0
		atts=["IPport", "uIP", "url", "ua", "host", "tmstp", "status", "length", "dataSz", "dur"]		
		f=Hash.new
		File.foreach(@defines.traceFile) {|line|
			if count==0		# HEADER
				#atts=@options['headers']
				atts.each{|a| f[a]=File.new(@defines.dirs['dataDir']+a,'w') if (a!='url')}
			else
				row=Format.columnsFormat(line,@defines.column_Format,@options)
				if row['host'].size>1 and row['host'].count('.')>0
					if function==1 or function==0
						atts.each{|att| (f[att].puts row[att]) if (att!='url')}
						Utilities.separateTimelineEvents(row,@defines.dirs['userDir']+row['IPport'],@defines.column_Format)
					elsif function==2 or function==0
						@func.parseRequest(row,false)
					elsif function==3
						@func.findStrInRows(row,str)
					end
				end
			end
			count+=1
        }
		if function==1 or function==0
			atts.each{|a| f[a].close if f[a]!=nil; Utilities.countInstances(@defines.dirs['dataDir']+a); }
		end
		if function==2 or function==0
			@func.analysis
		end
        puts "\t"+count.to_s+" rows have been loaded successfully!"
		@func.database.close
	end

	def makeTimelines(msec,path)
		@func.window=msec.to_i #store in msec
		@func.cwd=path
		cwd=path
		puts "> Start creating user timelines using window: "+msec+" msec"
		path=cwd+@defines.userDir
		entries=Dir.entries(path) rescue entries=Array.new
		if entries.size > 3 # DIRECTORY EXISTS AND IS NOT EMPTY
			puts "> Found existing per user files..."
			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
			@func.readUserAcrivity(entries)
		else
			if not File.exists?(cwd)
				puts "Dir not found"
			else
				Utilities.error("THIS FUNCTION NEEDS REVISION")
	#			Dir.mkdir path unless File.exists?(path)
	#			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
	#			puts "> There is not any existing user files. Separating timeline events per user..."
				# Post Timeline Events Separation (per user)
	#			if not File.exists? cwd+@defines.dataDir
	#				puts "Error: No file exists please run again with -s option"
	#			else
	#				@func.createTimelines()
	#			end
			end
		end
	end

	def plot(path)
		@defines.dirs['rootDir']=path
		@defines.dirs['plotDir']=@defines.dirs['rootDir']+@defines.plotDir
		Dir.mkdir @defines.dirs['plotDir'] unless File.exists?(@defines.dirs['plotDir'])
		if @database==nil
			@database=Database.new(@defines.dirs['rootDir']+@defines.resultsDB,@defines,nil)
		end
		plotter=Plotter.new(@defines,@database)
		puts "> Plotting existing output from <"+path+">..."
		
		#DB-BASED
		whatToPlot={"priceTagPopularity" => ["priceTable","priceTag"],
					"priceTagsPerDSP" => ["priceTable","host"],
					"beaconTypesCDF" => ["bcnTable","beaconType"],
					"categoriesTrace" => ["traceTable","advertising,analytics,social,content,beacons,other"],
				#	"percSizeCategoryPerUser" => ["userTable","sizesPerContentPerUser"],
				#	"categoriesPerUserCDF" => ["userTable","advertising,analytics,social,content,noAdBeacons,other"]
				#	 => ["userTable","advertising,analytics,social,content,noAdBeacons,other,thirdPartySize"]
					}
		whatToPlot.each{|name, specs|	plotter.plotDB(name,specs)}

		#FILE-BASED
	#	plotter.plotFile()
	end
end
