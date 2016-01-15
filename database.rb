require 'sqlite3'
require 'uri'

class Database

	def initialize(path)
		@db=SQLite3::Database.open path
	end

	def insert(table, params)
		sanitized=sanitizeStr(params)
		return execute("INSERT INTO '#{table}' VALUES ",sanitized)
	end

	def create(table,params)
		return execute("CREATE TABLE IF NOT EXISTS '#{table}' ",params) 
	end

	def get(table,what,param,value)
		sanitized=sanitizeStr(value)
		begin
			if what==nil
				return @db.get_first_row "SELECT * FROM '#{table}' WHERE "+param+"='#{sanitized}'"	
			else
				return @db.get_first_row "SELECT '#{what}' FROM '#{table}' WHERE "+param+"='#{sanitized}'"	
			end
		rescue SQLite3::Exception => e 
			puts "SQLite Exception during GET! "+e.to_s+"\n"+table+" "+param+" "+value
			abort
		end
	end

	def close
		puts "FREED"
		@db.close if @db
	end
# -------------------------------------------

private

	def sanitizeStr(str) 
		s=URI.encode(str,"'")
		puts s
		return s
	end

	def execute(command,params)
		begin
			@db.execute command+"("+params+")"
			return true
		rescue SQLite3::Exception => e 
			if e.to_s.include? "no such table" 
				# DO NOTHING
			else
				puts "SQLite Exception "+command.split(" ")[0]+"! "+e.to_s+"\n"+params
			end
			return false
		end
	end
end
