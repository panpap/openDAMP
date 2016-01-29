require 'sqlite3'
require 'uri'

class Database

	def initialize(path,defs,options)
		@db=SQLite3::Database.open path
		@defines=defs
		@options=options
		@alerts=Hash.new(0)
	end

	def insertRow(table, params)
		return if blockOutput(table)
		par=prepareStr(params)
		id=Digest::SHA256.hexdigest (params[0]+"|"+params[3])	#timestamp|url
		par="\""+id+"\","+par
		return execute("INSERT INTO '#{table}' VALUES ",par)
	end

	def insert(table, params)
		return if blockOutput(table)
		par=prepareStr(params)
		return execute("INSERT INTO '#{table}' VALUES ",par)
	end

	def create(table,params)
		return if blockOutput(table)
		return execute("CREATE TABLE IF NOT EXISTS '#{table}' ",params) 
	end

	def count(table)
		return @db.get_first_value("select count(*) from "+table)
	end

	def get(table,what,param,value)
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
			puts "SQLite Exception during GET! "+e.to_s+"\n"+table+" "+param+" "+value
			abort
		end
	end

	def getAll(table,what,param,value)
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
		puts "FREED"
		print @alerts.to_s+"\n"
		@db.close if @db
	end
# -------------------------------------------

private

	def blockOutput(table)
		return false #true if table.eql? @defines.tables["bcnTable"] or table.eql? @defines.tables["priceTable"] or table.eql? @defines.tables["adsTable"] or table.eql? @defines.tables["publishersTable"]
		#options
	end

	def prepareStr(input)
		res=""
		if input.is_a? String 
			res='"'+input+'"'
		else
			input.each{ |s| 
				if s.is_a? String
					str='"'+s+'"'
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
				# DO NOTHING
			elsif e.to_s.include? "is not unique"
					table=command.split("INTO")[1].split("VALUES")[0].gsub("'","")
					if @alerts[table]==nil or @alerts[table]==0
						puts "Warning: not unique: "+table
						puts command+"("+params+")"	
					end
					@alerts[table]+=1
			elsif e.to_s.include? "UNIQUE constraint failed"
					table=e.to_s.split(":")[1].split(".")[0]
					if @alerts[table]==nil or @alerts[table]==0
						puts "Warning: UNIQUE constraint failed: "+table	
					end
					@alerts[table]+=1
			else
				puts "SQLite Exception: "+command+" "+e.to_s+"\n"+params
			end
			return false
		end
	end
end
