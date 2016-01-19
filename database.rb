require 'sqlite3'
require 'uri'

class Database

	def initialize(path,defs)
		@db=SQLite3::Database.open path
		@defines=defs
	end

	def insert(table, params)
		par=prepareStr(params)
		if not table==@defines.tables['userTable'] and not table==@defines.tables['priceTable']
			id=Digest::SHA256.hexdigest (params[0]+"|"+params[3])	#timestamp|url
			par=id+par
		end	
		return execute("INSERT INTO '#{table}' VALUES ",par)
	end

	def create(table,params)
		return execute("CREATE TABLE IF NOT EXISTS '#{table}' ",params) 
	end

	def get(table,what,param,value)
		par=prepareStr(value)
		begin
			if what==nil
				return @db.get_first_row "SELECT * FROM '#{table}' WHERE "+param+"="+par	
			else
				return @db.get_first_row "SELECT '#{what}' FROM '#{table}' WHERE "+param+"="+par
			end
		rescue SQLite3::Exception => e 
			puts "SQLite Exception during GET! "+e.to_s+"\n"+table+" "+param+" "+value
			abort
		end
	end

	def getAll(table,what,param,value)
		if param==nil
			if what==nil
				return @db.execute "SELECT * FROM '#{table}'"	
			else
				return @db.execute "SELECT "+what+" FROM '#{table}'"
			end
		else
			if what==nil
				return @db.execute "SELECT * FROM '#{table}' WHERE "+param+"="+par	
			else
				return @db.execute "SELECT "+what+" FROM '#{table}' WHERE "+param+"="+par
			end
		end
	end

	def close
		puts "FREED"
		@db.close if @db
	end
# -------------------------------------------

private

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
			else
				puts "SQLite Exception "+command+"! "+e.to_s+"\n"+params
			end
			return false
		end
	end
end
