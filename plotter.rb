#load 'binCreator.rb'

class Plotter
	
	def initialize(defs,database)
		@defines=defs	
		@db=database
		@totalRows=nil
		if @db!=nil
			res=@db.get("traceResults","totalRows","users",@db.count(@defines.tables['userTable']).to_s)
			if res!=nil
				@totalRows=res[0]
			end
		end
		if @totalRows==nil
			IO.popen('wc -l '+@defines.dirs["adsDir"]+"devices.csv") { |io| @totalRows=io.gets.split(" ")[0] }
			if @totalRows==nil
				IO.popen('wc -l '+@defines.traceFile) { |io| @totalRows=io.gets.split(" ")[0] }
				if @totalRows==nil	
					Utilities.error  "Cannot estimate total rows"
				end
			end
		end
		puts @totalRows
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
				puts fl
				tempOut=".temp.data"
				param=fl.split("_")[0]				
				title=param.split(".")[0]
				out=@defines.dirs['plotDir']+fl.split(".")[0]+".eps"
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
					system("awk '{print ($1*100/"+@totalRows.to_s+")\" \"$2}' "+folder+fl+" > "+tempOut)
					plotscript="plot2.gn"			
				end
				if not fl.include? "Params"
					system("gnuplot -e \"y=0;x=0;xTitle=\'"+title+"\';t1='';t2=''\" "+plotscript+" > "+out)
				elsif double==1
					system("gnuplot -e \"y=0;x=1;xTitle=\'"+title+"\';"+s+"\" "+plotscript+" > "+out)	
					double=-1
				end
			end
		end
	end

	def plotDB(whatToPlot,specs)
		table=@defines.tables[specs[0]]
		column=specs[1]
		tempFile=".temp"
		print whatToPlot+" "+specs.to_s+"\n"		
		if column.include? ","	# plot more than one columns
			multipleColumns(table,column,whatToPlot,nil)
			return
		end
		outFile=@defines.dirs['plotDir']+whatToPlot+'.data'
		data=getDBdata(table,column)
		return if data==nil
		if data[0][0].include? "["
			multipleColumns(table,column,whatToPlot,data)
			return
		end
		case whatToPlot
		when "priceTagPopularity", "beaconTypesCDF"
			ft=File.open(tempFile,'w')
			instances=data.each_with_object(Hash.new(0)) { |word, counts| counts[word[0].to_s.downcase.split("&")[0]] += 1 }
			instances.sort.each{|word, count| ft.puts (count.to_f*100/data.size.to_f).to_s+" \""+word.gsub(/([_])/,"\\\\\\_")+"\""}
			ft.close	
			system("sort -rg "+tempFile+" > "+outFile+"; rm -f "+tempFile)
			if whatToPlot=="priceTagPopularity"
				plotIt(outFile,"Price tags detected","Percentage of reqs","zoomed",whatToPlot)
			else
				plotIt(outFile,"Beacon type", "Percentage of reqs","linespoints", whatToPlot)
			end
		when "priceTagsPerDSP"
			fw=File.open(tempFile,'w')
			instances=data.each_with_object(Hash.new(0)) { |word, counts| counts[word[0].to_s.downcase] += 1 }
			instances.each{|word, count| fw.puts (count.to_f*100/data.size.to_f.round(2)).to_s}
			fw.close
			total=0
			IO.popen('wc -l '+tempFile) { |io| total=io.gets.split(" ")[0] }
			system("awk '{print $1}' "+tempFile+" |sort -g| uniq -c | awk '{print ($1/"+total.to_s+")\" \"$2}' | awk '{for(i=1;i<=NF;i++);s=s+$1;print s\" \"$2;}' > "+outFile+"; rm -r "+tempFile)
			plotIt(outFile,"Percentage of reqs with prices", "CDN","cdf",whatToPlot)
		else
			Utilities.error "Uknown command to plotter"
		end


#			elsif data.size==1	# plotting ygram

#			else	# ploting instances
#				f=File.open('.'+column+'2.data','w')
#				instances=data.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
#				plotscript=""
#				if Utilities.is_numeric?(data[0])
#					plotscript="plot1.gn"
#					s=0
#					instances.each{|word, count| s+=count.to_f/data.size.to_f; f.puts word[0].gsub(/([_])/,'\_')+" "+s.to_s+" "+(count.to_f/data.size.to_f).to_s}	
#				end
	end

#-------------------------------------------

	private

	def plotIt(fromFile,xTitle,yTitle,script,name)
		system("gnuplot -e \"fromFile=\'"+fromFile+"\';yTitle=\'"+yTitle+"\';xTitle=\'"+xTitle+"\'\" "+
						@defines.plotScripts[script]+" > "+@defines.dirs['plotDir']+name+".eps")
	end

	def getDBdata(table,column)
		data=@db.getAll(table,column,nil,nil).sort
		if data.size==0
			Utilities.warning "No data was found in table: <"+table+"> column: <"+column+">"
			return nil
		end
		return data
	end

	def printInstances(fw,instances,total)
		cats=Array.new(6)
		for i in 0...instances.size
			s=0; instances[i].sort.each{|key, value| s+=(value.to_f/total.to_f); cats[i]=Array.new if cats[i]==nil; cats[i].push(s.to_s+";"+key.to_s+";");} 
		end
		i=0
		while i<cats.last.size do
			cats.each{|cat| 
				if (cat[i]!=nil) 
					fw.print cat[i]; else fw.print ";;" 	end}
			fw.puts
			i+=1			
		end
	end

	def multipleColumns(table,column,whatToPlot,data)				
		data=Hash.new(Array.new)
		columns=column.split(",")
		columns.each{|c| data[c]=(@db.getAll(table,c,nil,nil).flatten)}
		outFile=@defines.dirs['plotDir']+whatToPlot+'.data'
		fw=File.new(outFile,'w')
		plotType="";xTitle="";yTitle=""
		case whatToPlot
		when "categoriesTrace"
			plotType="bars"; xTitle="Categories"; yTitle="Percentage of reqs"
			totalRows=0
			data.each{|key, value| totalRows+=value[0].to_i}
			data.each{|key, value| value=value[0].to_f;	fw.puts key+"\t"+(value*100/totalRows).to_s}
		when "percSizeCategoryPerUser"
			plotType="cdf";	xTitle="Percentage of Total Volume"; yTitle="CDF"
			instances=Array.new()
			data.values.each{|user| user.each{|cell| 
				arrays=cell.gsub(/([\[\]])/,"").split(","); 
				total=arrays.inject{|sum,x| sum.to_f + x.to_f };i=0;
				arrays.each{|elemOfCat| 
				if instances[i]==nil
					instances[i]=Hash.new(0)
				end
				if elemOfCat.to_f==0
					instances[i][elemOfCat.to_i]+=1
				else
					instances[i][(elemOfCat.to_f*100/total.to_f).to_i]+=1
				end 
				i+=1; } 
			}}
			total=instances[0].values.inject(:+)
			printInstances(fw,instances,total)
		when "categoriesPerUser"
			xTitle="Percentage of reqs"; yTitle="CDF"; plotType="cdf"
			cats=Array.new(6)
			instances=Array.new
			i=0
			data.each{|key, value| cats[i]=Array.new if cats[i]==nil; cats[i].push(value.flatten);i+=1}
			for j in 0...cats.first.first.size
				total=0; s=''
				for i in 0...cats.size
					total+=cats[i][0][j].to_i
				end
				for i in 0...cats.size
					instances[i]=Hash.new(0) if instances[i]==nil
					if cats[i][0][j].to_f==0
						instances[i][cats[i][0][j].to_i]+=1
					else
						temp=(cats[i][0][j].to_f*100/total.to_f).to_i
						instances[i][temp]+=1
					end
				end
			end
			printInstances(fw,instances,cats.first.first.size)
		when "sizesPerReqsOfUsers"
			plotType="stacked_area"; xTitle="Total Bytes downloaded/req"; yTitle="Percentage of reqs"
			userSizes=Array.new(6)
			data[columns.last].each{|user|
				sizesRow=user.gsub(/([\[\]])/,"").split(","); 
				total=sizesRow.inject{|sum,x| sum.to_f + x.to_f };i=0;
				sizesRow.each{|elemOfCat| 
					if userSizes[i]==nil
						userSizes[i]=Array.new
					end
					userSizes[i].push(elemOfCat.to_i)
				i+=1; }}
			numOfUsers=data[columns.last].size
			for i in 0...numOfUsers
				data.each{|cat,reqs| 
					c=0;
					fw.print c.to_s+"="+userSizes[c][i].to_s+"/"+reqs[i].to_s+"\t" if cat!=data.keys.last			
					c+=1;
				}
				fw.puts ;
			end
				
		else
			Utilities.error "Wrong command"

#		if columns.size==8
#			tdata.each{|row| total=0; row.each{|x| total+=x if x!=row.last};
#				row.each{|cell| 
#				s=nil
#				if (cell==row.last) 
#					s=cell
#				else
#					s=(cell.to_f*100/total.to_f); 
#				end 
#				fw.print s.to_s+" " }; 
#			fw.print "\n"}
#			fw.close
#			tempFile2=".temp2.data"
#			system("echo "+columns[columns.size-1]+" "+columns.to_s.gsub(/([\[\]])/,"").gsub(","," ")+"> "+tempFile2)
#			system("awk '{print $8/1000\" \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7}' "+tempFile+" | sort -gk1 >> "+tempFile2)
#			makeBins(1,tempFile2)
		end
		fw.close
		plotIt(outFile,xTitle,yTitle,plotType,whatToPlot)
	end

	def makeBins(c,tempFile2)
		binAd=Array.new
		binEx=Array.new
		binAn=Array.new
		binSoc=Array.new
		binCon=Array.new
		binBea=Array.new
		binOth=Array.new
		f=File.new(tempFile2)
		fw=File.new(".temp.data",'w')
		#log
		if c==1
			i=10;b=1
		#binary
		elsif c==2
			i=10
		#exponential
		elsif c==3
			i=10;b=10
		end
		size=nil
		while(line=f.gets) do
			elem=line.split(" ")
			if Utilities.is_numeric?(elem[0])
				if elem[0].to_i>i
			
					if c==1
						i,b=log(i,b)
					elsif c==2
						i=binary(i)			
					elsif c==3
						i,b=exponential(i,b)
					end			
					print elem[0].to_i.to_s+"\n"
					size=elem[0].to_i.to_s
					output(fw,binAd,binEx,binAn,binSoc,binCon,binBea,binOth,size)
					binAd=Array.new
					binEx=Array.new
					binAn=Array.new
					binSoc=Array.new
					binCon=Array.new
					binBea=Array.new
					binOth=Array.new
				end
				binAd.push(elem[1].to_f)
				binEx.push(elem[2].to_f)
				binAn.push(elem[3].to_f)
				binSoc.push(elem[4].to_f)
				binCon.push(elem[5].to_f)
				binBea.push(elem[6].to_f)
				binOth.push(elem[7].to_f)
				size=elem[0].to_i.to_s
			else
				fw.puts line.gsub("other","\"actual content\"")
			end
		end
		if c<3
			output(fw,binAd,binEx,binAn,binSoc,binCon,binBea,binOth,size)
		end
		fw.close
		f.close
		system("gnuplot stacked_area.gn; mv *.eps "+@defines.dirs['plotDir'])
	end

	def output(fw,binAd,binEx,binAn,binSoc,binCon,binBea,binOth,size)
		a=Utilities.makeStats(binAd)['avg']
		a1=Utilities.makeStats(binEx)['avg']
		a2=Utilities.makeStats(binAn)['avg']
		a3=Utilities.makeStats(binSoc)['avg']
		a4=Utilities.makeStats(binCon)['avg']
		a5=Utilities.makeStats(binBea)['avg']
		a6=Utilities.makeStats(binOth)['avg']
		sum= (a+a1+a2+a3+a4+a5+a6).to_s
#		fw.puts size+" "+a.to_s+" "+a1.to_s+" "+a2.to_s+" "+a3.to_s+" "+a4.to_s+" "+a5.to_s+" "+a6.to_s+" "+sum
		fw.puts size+" "+a.to_s+" "+a1.to_s+" "+a2.to_s+" "+a3.to_s+" "+a5.to_s+" "+(a4+a6).to_s+" "+sum
	end

	def exponential(i,b)
		if i==100 or i==1000 or i==10000
			b*=10
		end
		i+=b; 
		print i.to_s+" "+b.to_s+" "
		return i,b
	end

	def log(i,b)
		b+=1;
		i=10**b
		print i.to_s+" "+b.to_s+" "
		return i,b
	end

	def binary(i)
		print i.to_s+" "
		return i*2
	end
end
