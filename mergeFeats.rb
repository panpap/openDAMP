load 'define.rb'
load "utilities.rb"

def getBinding(array,id,name)
	array.each do |row|
		return row if row[name]==id
	end
end

def printer(fw,arrayAttrs,data)
	arrayAttrs.split("\t").each{|col| fw.print data[col.split(":").last].to_s+"\t"}
end

filename=ARGV[0]
columns=["price:type\tprice:priceValue\tprice:bytes\tprice:upToKnowCM\tprice:numOfParams\tprice:adSize\tprice:adPosition\tprice:userLocation\tprice:TOD\tprice:interest\tprice:pubPopularity\tprice:associatedSSP\tprice:associatedDSP\tprice:associatedADX\tprice:mob\tprice:browser\tprice:device\t", #PRICE-RELATED
"user:totalRows\tuser:numOfLocations\tuser:uniqLocations\tuser:totalBytes\tuser:avgBytesPerReq\tuser:sumDuration\tuser:avgDurationOfReq\tuser:numOfCookieSyncs\tuser:publishersVisited\t","user:interests\t", #USER-RELATED
"adv:numOfReqs\tadv:numOfUsers\tadv:avgReqPerUser\tadv:totalDurOfReqs\tadv:avgDurOfReqs\tadv:totalBytesDelivered\tadv:type\t"] #ADVERTISERS-RELATED
trace=""
path=""
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
fw=File.new(writeFile,"w")
columns.each{|col| fw.print col}; fw.puts ;
prices.each do |row|
    userInterest=getBinding(interests,row['userId'],"userID")
	advertiser=getBinding(advertisers,row['host'],"host")
	user=getBinding(users,row['userId'],"id")
	printer(fw,columns[0],row)
	printer(fw,columns[1],user)
	printer(fw,columns[2],userInterest)
	printer(fw,columns[3],advertiser)
	fw.puts ;
end
fw.close