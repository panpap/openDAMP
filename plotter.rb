module Plotter
	def Plotter.plotFile(folder)
		files=Dir.entries(folder) rescue entries=Array.new
		for fl in files do
			if fl.include? "_cnt"
				puts fl
				total="1"
				param=fl.split("_")[0]
				IO.popen('wc -l '+folder+param) { |io| total=io.gets.split(" ")[0] }
				system("cat "+folder+fl+" | awk '{gsub(\",\",\".\"); print}' > temp.data")
puts "NEEDS TO BE CUMULATIVE"
				if Utilities.is_numeric?((File.open(folder+fl, &:readline)).split(" ")[1])
					plotscript="plot1.gn"
					out=folder+fl.split(".")[0]+"CDF.eps"
				else
					system("cat "+folder+fl+" | awk '{print ($1/"+total+")\" \"$2}' | awk '{gsub(\",\",\".\"); print}' > temp.data")
					plotscript="plot2.gn"
					out=folder+fl.split(".")[0]+".eps"
				end
				system("gnuplot -e \"xTitle=\'"+param.split(".")[0]+"\'\" "+plotscript+" > "+out)
			end
		end
	end

	def Plotter.plotDB(db,table,column,folder)
		data=db.getAll(table,column,nil,nil).sort
		instances=data.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }		
		f=File.open('temp','w')
		s=0
		plotscript=""
		if Utilities.is_numeric?(data[0])
			plotscript="plot1.gn"
			instances.each{|word, count| s+=count.to_f/data.size.to_f; f.puts word[0]+" "+s.to_s+" "+(count.to_f/data.size.to_f).to_s}		
		else 
			plotscript="plot2.gn"
			instances.each{|word, count| f.puts count.to_s+" "+word[0]}	
		end
		f.close
		system("sort -rg temp > temp.data")
		system("gnuplot -e \"xTitle=\'"+column+"\'\" "+plotscript+" > "+folder+column+"CDF.eps")
	end
end
