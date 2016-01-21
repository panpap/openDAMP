class Plotter
	
	def initialize(defs,database)
		@defines=defs	
		@db=database
	end

	def plotFile()
		folder=@defines.dirs['adsDir']
		double=-1
		adFile=@defines.files['adParamsNum'].split(folder)[1].split(".")[0]
		restFile=@defines.files['restParamsNum'].split(folder)[1].split(".")[0]
		s=""
		files=Dir.entries(folder) rescue entries=Array.new
		for fl in files do
			if fl.include? "_cnt"
				total="1"
				tempOut=".temp.data"
				param=fl.split("_")[0]				
				title=param.split(".")[0]
				out=folder+fl.split(".")[0]+".eps"
				if fl.include? "Params"
					title='Number of URL params'
					out=folder+"noOfparamsCDF.eps"
					double+=1
					if double==0
						tempOut=".temp2.data"
						if fl.include? adFile
							s="t1='ad-related';t2='"
						elsif fl.include? restFile
							s="t1='rest';t2='"
						end
					end
					if double==1
						if fl.include? adFile
							s=s+"ad-related'"
						elsif fl.include? restFile
							s=s+"rest'"
						end
					end
				end
				IO.popen('wc -l '+folder+param) { |io| total=io.gets.split(" ")[0] }
				if Utilities.is_numeric?((File.open(folder+fl, &:readline)).split(" ")[1])
					system("sort -gk2 "+folder+fl+" | awk '{print ($1/"+total+")\" \"$2}' | awk '{for(i=1;i<=NF;i++);s=s+$1;print s\" \"$2;}' > "+tempOut)
					plotscript="plot1.gn"
				else
					system("mv "+folder+fl+" "+tempOut)
					plotscript="plot2.gn"			
				end
				if not fl.include? "Params"
					system("gnuplot -e \"histo=;x=0;xTitle=\'"+title+"\';t1='';t2=''\" "+plotscript+" > "+out)
				elsif double==1
					system("gnuplot -e \"histo=0;x=1;xTitle=\'"+title+"\';"+s+"\" "+plotscript+" > "+out)	
					double=-1
				end
			end
		end
	end

	def plotDB(table,column)
		data=@db.getAll(table,column,nil,nil).sort
		histo=0
		if data.size==1	# plotting histogram
			# Nested array
			f=File.open('.temp.data','w')
			newdata=data[0][0].gsub(/([\[\]])/,"").split(",")
			if(newdata.size==6)	# Content of Req
				data={"Advertising"=>newdata[0],"Analytics"=>newdata[1],"Social"=>newdata[2],"Content"=>newdata[3],"Beacons"=>newdata[4],"Other"=>newdata[5]}
				histo=1
				data.each{|key, value| f.puts value+" "+key}
				plotscript="plot2.gn"
			end
			f.close
		else	# ploting instances
			f=File.open('.temp2.data','w')
			instances=data.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
			plotscript=""
			if Utilities.is_numeric?(data[0])
				plotscript="plot1.gn"
				s=0
				instances.each{|word, count| s+=count.to_f/data.size.to_f; f.puts word[0]+" "+s.to_s+" "+(count.to_f/data.size.to_f).to_s}		
			else 
				plotscript="plot2.gn"
				instances.each{|word, count| f.puts count.to_s+" "+word[0]}	
			end
			f.close
			system("sort -rg .temp2.data > .temp.data")
		end
		system("gnuplot -e \"x=0;histo="+histo.to_s+";t1='';t2='';xTitle=\'"+column+"\'\" "+plotscript+" > "+@defines.dirs['adsDir']+column+".eps")
	end
end
