require 'sqlite3'
require 'csv'

def getAll(db,tbl,what,param,value,hash)
	db.results_as_hash = true if hash
	table=arrayCase(tbl)
	return if table==nil
	if param==nil
		if what==nil
			return db.execute "SELECT * FROM '#{table}'"	
		else
			return db.execute "SELECT "+what+" FROM '#{table}'"
		end
	else
		val=prepareStr(value)
		if what==nil
			return db.execute "SELECT * FROM '#{table}' WHERE "+param+"="+val	
		else
			return db.execute "SELECT "+what+" FROM '#{table}' WHERE "+param+"="+val
		end
	end
end

def getColumnNames(db,tbl)
	table=arrayCase(tbl)
	return if table==nil
	result=db.prepare "SELECT * FROM '#{table}'"
	return result.columns
end

def prepareStr(input)
	res=""
	if input.is_a? String 
		res='"'+input.gsub('"',"%22")+'"'
	else
		input.each{ |s| 
			if s.is_a? String
				str='"'+s.gsub("\n","").gsub('"',"%22")+'"'.force_encoding("iso-8859-1")
			else
				str=s.to_s.force_encoding("iso-8859-1")
			end
			if res!=""
				res=res+","+str.force_encoding("iso-8859-1")
			else
				res=str
			end}
	end
	return res
end

def arrayCase(tbl)
	if tbl.kind_of?(Hash)	
		return tbl.keys[0] 
	else		#beaconsURL
		return tbl
	end
end

def readDB(table)
	CSV.open(table+"_summary.csv","w",{:col_sep => "\t"}) do |summary|
		for i in 1..12
			month="0"
			if i.to_s.size==1
				month="0"+i.to_s
			else
				month=i.to_s
			end		
			for j in [10,20,30]
				dbname="results/"+"chechpoint1"+"/2015"+month+"_"+j.to_s+"/results_month_2015"+month+"_"+j.to_s+"days_filtered_ES_sorted_uniq/month_2015"+month+"_"+j.to_s+"days_filtered_ES_sorted_uniq_analysis.db"
				if File.exist? dbname
					db=SQLite3::Database.open dbname
					results=getAll(db,table,nil,nil,nil,false)
					columnNames=getColumnNames(db,table)
					CSV.open(dbname.rpartition("/")[0]+"/"+table+".csv","w",{:col_sep => "\t"}) do |csv|
						csv << columnNames
						summary << columnNames
						results.each { |row| csv << row; row.unshift(dbname.rpartition("/")[0].split("month_")[1].split("days")[0]); summary << row}
					end
				else
					puts "NOTEXISTS: "+dbname
				end
			end
		end
	end
end

table="userResults"
puts table+" -------------"
readDB(table)
readDB(table+"_app")
readDB(table+"_web")
table="traceResults"
puts table+" -------------"
readDB(table)
readDB(table+"_app")
readDB(table+"_web")
table="csyncResults"
puts table+" -------------"
readDB(table)
