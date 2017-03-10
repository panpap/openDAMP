def tokenize(line)
	row=Hash.new
	begin
#		part=line.split('"')
#		row["NodeIP"]=part[0].split(" - ")[0]
#		row["UserIP"]=part[0].split(" - ")[1]
#		row["TimeStamp"]=part[0].split(" - ")[2].gsub("[","").gsub("]","").gsub(" ","")
#		row["Verb"]=part[1].split(" ")[0]
#		row["Path"]=part[1].split(" ")[1]
#		row["HttpVersion"]=part[1].split(" ")[2]
#		row["HttpReferer"]=part[1].split(" ")[3]
#		row["ResponseCode"]=part[2].split(" ")[0]
#		row["ContentLength"]=part[2].split(" ")[1]
#		row["DeliveredData"]=part[2].split(" ")[2]
#  	 	row["Duration"]=part[2].split(" ")[3]
#    	row["NumericHitOrMiss"]=part[2].split(" ")[4]
 #   	row["UserAgent"]=part[3]
  #  	bracks=line.split("{")
   # 	row["RequestHeaders"]=bracks[1].split("}")[0]
  #  	row["ResponseHeaders"]=bracks[2].split("}")[0]
  #  	temp=line.split("}").last.split("] ")
  #  	row["IncomingPort"]=temp[0].split(" [")[1]
  #  	row["OriginalSize"]=temp[1].split(" ")[0]
  #  	rest=line.split("(").last.gsub(")","")
  #  	row["Country"]=rest.split(",")[14]
  		temp=line.split(",")
    	row["Country"]=temp[temp.size-6]
    rescue Exception => e
    	abort "Error -> "+e.backtrace.to_s+"\n"+line.to_s
    end
    return row
end

folderPath="/home/sysadmin/data/log_done/"
month=nil
fw=nil
Dir.entries(folderPath).sort.each {|f| 
	next if File.directory? f or f.include? ".done" or f.include? ".gz" #remove dirs and .done and .gz files
	traceFile=f
	#puts traceFile	
	timestmp=traceFile.split(".")[0]
	next if not timestmp.include? "2015" # keep only 2015
	if month!=timestmp[4...6]
		fw.close if fw!=nil
		month=timestmp[4...6]
		fw=File.new("month_2015"+month,"w")
		puts month
	end
	system("sort "+folderPath+"/"+traceFile+" | uniq > tempSort")
	File.foreach("tempSort") {|line|
		next if line.include? "/awazzaredirect/" # Duplicate removal
		row=tokenize(line.chop.force_encoding("iso-8859-1"))
		next if row["Country"]!="ES"
		next if line.include? "CONNECT"
		#abort "SCREAM" if row["RequestHeaders"].downcase.include? "cookie"
		fw.puts line
	}
}
fw.close
system("rm -rf tempSort")