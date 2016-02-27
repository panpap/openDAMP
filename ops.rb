load 'define.rb'
load 'core.rb'
load 'plotter.rb'
load 'columnsFormat.rb'

class Operations
	
	def initialize(filename)
		@defines=Defines.new(filename)
		if @defines.traceFile!="" and @defines.resultsDB!=nil
			@filters=Filters.new(@defines)
			@func=Core.new(@defines,@filters)
		else
			@defines.puts "Done..."
			abort
		end
	end

	def dispatcher(function,str)	
		@func.makeDirsFiles
		@defines.puts "> Loading Trace... "+@defines.traceFile
		count=0
		count=1 if not @defines.options['isThereHeader?']
		#atts=@options['headers']
		atts=["IPport", "uIP", "url", "ua", "host", "tmstp", "status", "length", "dataSz", "dur"]		
		f=Hash.new
		File.foreach(@defines.traceFile) {|line|
			begin
			@defines.puts "\t"+count.to_s+" lines so far..." if count%10000==0
			if count==0		# options consume HEADER
				@defines.puts "\theader detected"
				if function==1 or function==0
					atts.each{|a| f[a]=File.new(@defines.dirs['dataDir']+a,'w') if File.size?(@defines.dirs['dataDir']+a)==nil and (a!='url') and (a!="tmstp") }
				end
			else
				row=Format.columnsFormat(line,@defines.column_Format,@defines.options,@filters)
				if row!=nil and row['host'].size>1 and row['host'].count('.')>0
					if function==1 or function==0
						atts.each{|att| (f[att].puts row[att]) if (att!='url' and att!="tmstp") and f[att]!=nil}
						Utilities.separateTimelineEvents(row,@defines.dirs['userDir']+row['IPport'],@defines.column_Format) #timelines creation
					end					
					if function==2 or function==0
						@func.parseRequest(row,true) 	#categorization,cookie synchronization and prices detection
					end
					if function==3		#find
						@func.findStrInRows(row,str)
					end
					if function==4		#find
						@func.cookieSyncing(row,nil)
					end
				end
			end
			rescue => e 
				Utilities.error "Exception: "+e.to_s+"\n"+line+"\n"+e.backtrace.join("\n").to_s
			end
			count+=1
        }
		@defines.puts "\t"+(count-1).to_s+" rows have been loaded successfully!"
		if function==1 or function==0
			atts.each{|a| f[a].close if f[a]!=nil; Utilities.countInstances(@defines.dirs['dataDir']+a); }
		end
		if function==2 or function==0
			@func.analysis
		end
		if function==4		#find
			@func.csyncResults()
		end
		@func.database.close if @func.database!=nil
	end

	def countDuplicates()
		uniq=""
		total=""
		if @defines.options['excludeCol']!=nil
			IO.popen("awk '{$"+@options['excludeCol'].to_s+"=\"\"; print $0}' "+@defines.traceFile+" | sort -u | wc -l") { |io| uniq=io.gets.split(" ")[0] }
			#awk 'NR == 1; NR > 1 {print $0 | "sort -uk1,3"}' trace > Sorted_trace
		else
			IO.popen("sort -u "+@defines.traceFile+" | wc -l") { |io| uniq=io.gets.split(" ")[0] }			
			#awk 'NR == 1; NR > 1 {print $0 | "sort -u"}' trace > Sorted_trace
		end
		IO.popen("wc -l "+@defines.traceFile) { |io| total=io.gets.split(" ")[0] }
		if (total.to_i-uniq.to_i)>0
			@defines.puts "> "+(total.to_i-uniq.to_i).to_s+" ("+(100-(uniq.to_f*100/total.to_f)).round(2).to_s+"%) dublicates were found in the trace"
		end
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
		if not File.exists? @defines.dirs['rootDir']
			Utilities.error "Directory does not exists."
			return
		end
		Dir.mkdir @defines.dirs['plotDir'] unless File.exists?(@defines.dirs['plotDir'])
		if @database==nil
			@database=Database.new(@defines,nil)
		end
		plotter=Plotter.new(@defines,@database)
		puts "> Plotting existing output from <"+path+">..."

		#FILE-BASED
	#	plotter.plotFile()		

		#DB-BASED
		whatToPlot={"priceTagPopularity" => ["priceTable","priceTag"],
					"priceTagsPerDSP" => ["priceTable","host"],
					"beaconTypesCDF" => ["bcnTable","beaconType"],
					"categoriesTrace" => ["traceTable","advertising,analytics,social,beacons,content,other"],
					"percSizeCategoryPerUser" => ["userTable","totalSizePerCategory"],
					"categoriesPerUser" => ["userTable","advertising,analytics,social,content,Beacons,other"],	
					"sizesPerReqsOfUsers"=> ["userTable","advertising,analytics,social,content,Beacons,other,totalSizePerCategory"] #stacked area
							#boxplot price values (normalized xaxis window/avg reqs
							#boxplot number of detected prices
					}
		whatToPlot.each{|name, specs|	plotter.plotDB(name,specs)}
	end
end
