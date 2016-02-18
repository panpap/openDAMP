require 'sqlite3'

class Database

	def initialize(defs,dbName)		
		@defines=defs
		if dbName==nil and defs!=nil
			@db=SQLite3::Database.open @defines.dirs['rootDir']+@defines.resultsDB
		else
			@db=SQLite3::Database.open dbName
		end
		if defs!=nil
			@options=@defines.options
		end
		@alerts=Hash.new(0)
	end

	def insert(tbl, params)
		table=arrayCase(tbl)
		return if blockOutput(table)
		par=prepareStr(params)
		return execute("INSERT INTO '#{table}' VALUES ",par)
	end

	def create(tbl,params)
		table=arrayCase(tbl)
		return if blockOutput(table)
		return execute("CREATE TABLE IF NOT EXISTS '#{table}' ",params) 
	end

	def count(tbl)
		table=arrayCase(tbl)
		return @db.get_first_value("select count(*) from "+table)
	end

	def get(tbl,what,param,value)
		table=arrayCase(tbl)
		if table==nil or param==nil or value==nil
			return
		end
		val=prepareStr(value)
		begin
			if what==nil
				return @db.get_first_row "SELECT * FROM '#{table}' WHERE "+param+"="+val	
			else
				return @db.get_first_row "SELECT "+what+" FROM '#{table}' WHERE "+param+"="+val
			end
		rescue SQLite3::Exception => e 
			Utilities.error "SQLite Exception during GET! "+e.to_s+"\n"+table+" "+param+" "+value
		end
	end

	def getAll(tbl,what,param,value)
		table=arrayCase(tbl)
		if table==nil
			return
		end
		if param==nil
			if what==nil
				return @db.execute "SELECT * FROM '#{table}'"	
			else
				return @db.execute "SELECT "+what+" FROM '#{table}'"
			end
		else
			val=prepareStr(value)
			if what==nil
				return @db.execute "SELECT * FROM '#{table}' WHERE "+param+"="+val	
			else
				return @db.execute "SELECT "+what+" FROM '#{table}' WHERE "+param+"="+val
			end
		end
	end

	def close
		if @alerts.size>0
			Utilities.warning "Your results may be biased..."
			puts "\tDublicates detected from Database: \n\t"+@alerts.to_s
		end
		@db.close if @db
	end
# -------------------------------------------

private

	def blockOutput(tbl)
		table=arrayCase(tbl)
		return false if @defines==nil
		blockOptions=@defines.options['tablesDB']
		return false if blockOptions[table]==nil
		return (not blockOptions[table])
	end

	def prepareStr(input)
		res=""
		if input.is_a? String 
			res='"'+input+'"'
		else
			input.each{ |s| 
				if s.is_a? String
					str='"'+s.gsub("\n","").gsub('"',"%22")+'"'
				else
					str=s.to_s
				end
				if res!=""
					res=res+","+str
				else
					res=str
				end}
		end
		return res
	end

	def execute(command,params)
		begin
			@db.execute command+"("+params+")"
			return true
		rescue SQLite3::Exception => e 
			if e.to_s.include? "no such table" 
				Utilities.error "SQLite Exception: "+e.to_s
			elsif e.to_s.include? "is not unique"
					table=command.split("INTO ")[1].split("VALUES")[0].gsub("'","")
					if @alerts[table]==nil or @alerts[table]==0
						Utilities.warning "not unique: "+table+"\n"+command+"("+params+")"
					end
					@alerts[table]+=1
			elsif e.to_s.include? "UNIQUE constraint failed"
					table=e.to_s.split(": ")[1].split(".")[0]
					if @alerts[table]==nil or @alerts[table]==0
						Utilities.warning "UNIQUE constraint failed: "+table+"\n"+command+"("+params+")"
					end
					@alerts[table]+=1
			else
				Utilities.error "SQLite Exception: "+command+" "+e.to_s+"\n"+params+"\n\n"+e.backtrace.join("\n").to_s
			end
			return false
		end
	end
	
	def arrayCase(tbl)
		if tbl.kind_of?(Hash)	
			return tbl.keys[0] 
		else		#beaconsURL
			return tbl
		end
	end
end
