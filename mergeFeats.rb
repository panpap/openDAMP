load 'define.rb'
load "utilities.rb"

def getBinding(array,id,name)
	array.each do |row|
		return row if row[name]==id
	end
end

def printer(fw,arrayAttrs,data,host)
	arrayAttrs.split("\t").each{|col| 
		header=col.split(":").last
		cell=data[header]
		if cell==nil
			puts "SOMETHING WENT WRONG! "+header
		else
			if header=="uniqLocations"
				locations=cell.gsub("%22","").gsub("{","").gsub("}","").split(",")
				@@cities.uniq.each{|city| found=false; locations.each{|loc|  loc=loc.gsub(" ","")
					if loc.include? city
						found=true
						fw.print loc.split("=>").last+"\t"
						break
					end
					}
					if not found
						fw.print "0\t"
					end}
			elsif header=="interests" or header=="interest"
				if cell=="-1"
					for i in 1..@@interestNum
						fw.print "0\t"
					end
				else
					cell.gsub("%22","").gsub("{","").gsub("}","").split(",").each{|interest| fw.print interest.split("=>").last+"\t"}
				end
			else
				fw.print cell.to_s+"\t"
			end
		end}
end

filename=ARGV[0]
columns=["price:type\tprice:priceValue\tprice:priceTag\tprice:host\tprice:bytes\tprice:upToKnowCM\tprice:numOfParams\tprice:adSize\tprice:carrier\tprice:adPosition\tprice:userLocation\tprice:TOD\tprice:publisher\tprice:interest\tprice:url\tprice:pubPopularity\tprice:associatedSSP\tprice:associatedDSP\tprice:associatedADX\tprice:mob\tprice:browser\tprice:device\t", #PRICE-RELATED
"user:totalRows\tuser:numOfLocations\tuser:uniqLocations\tuser:totalBytes\tuser:avgBytesPerReq\tuser:sumDuration\tuser:avgDurationOfReq\tuser:numOfCookieSyncs\tuser:publishersVisited\t","user:interests\t", #USER-RELATED
"adv:numOfReqs\tadv:numOfUsers\tadv:avgReqPerUser\tadv:totalDurOfReqs\tadv:avgDurOfReqs\tadv:totalBytesDelivered\tadv:type\t"] #ADVERTISERS-RELATED
trace=""
path=""
filename=filename.gsub("./","")
if filename!=nil
	str=filename.split("/")
	if str.size>1
		if filename.include? "_analysis"
			filename=filename.split(".").first
			trace=str.last
			path=str.first+"/"
		else
			Utilities.error "Wrong file"
		end
	else
		path=str.first+"/"
		trace=str.first.split("results_").last
		filename=path+trace+"_analysis"
	end
else
	Utilities.error "Give proper path"
end
writeFile=path+"mergedFeatures.csv"
defines=Defines.new(trace)
puts "Opening "+filename+".db"
db=Database.new(defines,filename+".db")
prices=db.getAll(defines.tables["priceTable"].keys.first,nil,nil,nil,true)
advertisers=db.getAll(defines.tables["advertiserTable"].keys.first,nil,nil,nil,true)
interests=db.getAll(defines.tables["visitsTable"].keys.first,nil,nil,nil,true)
users=db.getAll(defines.tables["userTable"].keys.first,nil,nil,nil,true)
@@cities=Array.new
users.each{|user| user['uniqLocations'].split(",").each{|c| @@cities.push(c.split("%22")[1])}}
@@cities=@@cities.uniq
@@interestNum=0
fw=File.new(writeFile,"w")
puts "print headers..."
columns.each{|cell|
	if cell.include? "price:interest"
		cell.split("\t").each{|col| 
			if col=="price:interest"
				interests.first['interests'].split(",").each{|c| @@interestNum+=1;fw.print c.split("%22")[1]+"\t"}
			else
				fw.print col+"\t"
		end}
	elsif cell.include? "user:uniqLocations" 
		cell.split("\t").each{|col| 
			if col=="user:uniqLocations"
				@@cities.each{|c| fw.print c+"\t"}
			else
				fw.print col+"\t"
			end}
	elsif cell.include? "user:interests"
		interests.first['interests'].split(",").each{|c| fw.print c.split("%22")[1]+"\t"}
	else
		fw.print cell
	end
	};	fw.puts ;
puts "print columns..."
prices.each do |row|
    userInterest=getBinding(interests,row['userId'],"userID")
	advertiser=getBinding(advertisers,row['host'],"host")
	user=getBinding(users,row['userId'],"id")
	printer(fw,columns[0],row,nil)
	printer(fw,columns[1],user,nil)
	printer(fw,columns[2],userInterest,nil)
	printer(fw,columns[3],advertiser,row['host'])
	fw.puts ;
end
fw.close
