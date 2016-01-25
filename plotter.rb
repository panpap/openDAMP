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
					system("awk '{print ($1*100/"+@totalRows+")\" \"$2}' "+folder+fl+" > "+tempOut)
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

	def plotDB(table,column)
		y=0
		puts column
		tempFile='.'+column+'.data'
		if column.include? ","	# plot more than one columns
			multipleColumns(table,column,tempFile)
			return
		end
		data=@db.getAll(table,column,nil,nil).sort
		if data.size==0
			puts "Warning: No data was found in =>\ntable: <"+table+"> \ncolumn: <"+column+">"
			return
		elsif data.size==1	# plotting ygram
			# Nested array
			f=File.open(tempFile,'w')
			newdata=data[0][0].gsub(/([\[\]])/,"").split(",")
			if(newdata.size==6)	# content of Req
				adBeacons=@db.getAll(table,"adRelatedBeacons",nil,nil)[0][0].gsub(/([\[\]])/,"").split("/")[0]
				data={"Advertising"=>newdata[0],"Analytics"=>newdata[1],"Social"=>newdata[2],"Beacons"=>(newdata[4].to_i-adBeacons.to_i).to_s,"\"3rd party Content\""=>newdata[3],"Rest"=>newdata[5]}
				y=1
				data.each{|key, value| f.puts (value.to_f*100/@totalRows.to_f).to_s+" "+key}
				plotscript="plot2.gn"
			end
			f.close
		else	# ploting instances
			f=File.open('.'+column+'2.data','w')
			instances=data.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
			plotscript=""
			if Utilities.is_numeric?(data[0])
				plotscript="plot1.gn"
				s=0
				instances.each{|word, count| s+=count.to_f/data.size.to_f; f.puts word[0].gsub(/([_])/,'\_')+" "+s.to_s+" "+(count.to_f/data.size.to_f).to_s}	
			else 
				plotscript="plot2.gn"
				instances.each{|word, count| f.puts (count.to_f*100/data.size.to_f).to_s+" \""+word[0].gsub(/([_])/,"\\\\\\_")+"\""}	
				if column=="host" and table=="prices"
					fw=File.open(tempFile,'w')
					instances.each{|word, count| fw.puts (count.to_f*100/data.size.to_f.round(2)).to_s}
					fw.close
					total=0
					IO.popen('wc -l '+tempFile) { |io| total=io.gets.split(" ")[0] }
					system("awk '{print $1}' "+tempFile+" |sort -g| uniq -c | awk '{print ($1/"+total.to_s+")\" \"$2}' | awk '{for(i=1;i<=NF;i++);s=s+$1;print s\" \"$2;}' > .temp.data")
					system("gnuplot -e \"x=0;y=1;xTitle=\'Percentage of reqs with prices\'\" plot1.gn > "+@defines.dirs['plotDir']+"pricesDSP_cdf.eps")
				end
			end
			f.close	
			system("sort -rg ."+column+"2.data > "+tempFile)
		end
		xtitle=table+"-"+column
		system("mv "+tempFile+" .temp.data")
		system("gnuplot -e \"x=0;y="+y.to_s+";t1='';t2='';xTitle=\'"+xtitle+"\'\" "+plotscript+" > "+@defines.dirs['plotDir']+xtitle+".eps")
	end


#-------------------------------------------

	private

	def multipleColumns(table,column,tempFile)
		fw=File.open(tempFile,'w')
		data=Array.new
		columns=column.split(",")
		columns.each{|c| data.push(@db.getAll(table,c,nil,nil).flatten)}
		tdata=data.transpose
		totals=Array.new
		if columns.size==8
			tdata.each{|row| total=0; row.each{|x| total+=x if x!=row.last};
				row.each{|cell| 
				s=nil
				if (cell==row.last) 
					s=cell
				else
					s=(cell.to_f*100/total.to_f); 
				end 
				fw.print s.to_s+" " }; 
			fw.print "\n"}
			fw.close
			tempFile2=".temp2.data"
			system("echo "+columns[columns.size-1]+" "+columns.to_s.gsub(/([\[\]])/,"").gsub(","," ")+"> "+tempFile2)
			system("awk '{print $8/1000\" \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7}' "+tempFile+" | sort -gk1 >> "+tempFile2)
			makeBins(1,tempFile2)
		elsif columns.size==7
			tdata.each{|row| total=(row.inject{|sum,x| sum + x }); row.each{|cell| fw.print (cell.to_f*100/total.to_f).to_i.to_s+" " }; fw.print "\n"}
			i=2
			fw.close
			while i<=data.size
				s="awk '{print $"+i.to_s+"}' "
				if i==2
					s="awk '{print ($1+$2)}' "
				elsif i==5
					s=nil
				elsif i==7
					s="awk '{print ($5+$7)}' "
				end
				if s!=nil
					system(s+tempFile+" | sort | uniq -c | sort -gk2  | awk '{print ($1/"+data[0].size.to_s+")\" \"$2}' | awk '{for(i=1;i<=NF;i++);s=s+$1;print s\" \"$2}' > .temp"+i.to_s+".data")
				end
				i+=1
			end
			system("gnuplot plot3.gn; mv content*.eps "+@defines.dirs['plotDir'])
		end
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
				fw.puts line.gsub("noAdBeacons","beacons").gsub("other","\"actual content\"")
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
