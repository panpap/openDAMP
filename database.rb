require 'sqlite3'

class Database

	def initialize(path)
		@db=SQLite3::Database.open path
	end

	def insert(table, params)
		puts params
		return execute("INSERT INTO '#{table}' VALUES ",params)
	end

	def create(table,params)
		return execute("CREATE TABLE IF NOT EXISTS '#{table}' ",params) 
	end

	def get(table,what,param,value)
		if what==nil
			return @db.get_first_row "SELECT * FROM '#{table}' WHERE "+param+"='#{value}'"	
		else
			return @db.get_first_row "SELECT '#{what}' FROM '#{table}' WHERE "+param+"='#{value}'"	
		end
	end

	def close
		puts "FREED"
		@db.close if @db
	end
# -------------------------------------------

private

	def execute(command,params)
		begin
			@db.execute command+"("+params+")"
			return true
		rescue SQLite3::Exception => e 
			if e.to_s.include? "no such table" 
				# DO NOTHING
			else
				puts "SQLite Exception! "+e.to_s+"\n"+row['url']
			end
			return false
		end
	end
end
