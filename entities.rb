class User
	attr_accessor :dur3rd, :uIPs, :csyncIDs, :pubVisits, :csyncHosts, :csync, :fileTypes, :publishers, :numericPrices, 
					:hashedPrices, :size3rdparty, :sizes3rd, :imp, :latency, :ads, :interests

	def initialize
		@hashedPrices=Array.new
		@numericPrices=Array.new
		@ads=Array.new
		@imp=Array.new
		@csyncIDs=Hash.new
		@csyncHosts=Hash.new
		@csync=Array.new
		@uIPs=Hash.new
		@interests=nil
		@pubVisits=Hash.new
		@publishers=Array.new
		@size3rdparty={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
		@dur3rd={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
		@fileTypes={"Advertising"=>nil,"Social"=>nil,"Analytics"=>nil,"Content"=>nil, "Other"=>nil, "Beacons"=>nil}
	end
end

class Advertiser

	attr_accessor :reqsPerUser, :type, :durPerReq, :sizePerReq #:totalReqs, 
	
	def initialize
		@reqsPerUser=Hash.new(0)
		#@totalReqs=0
		@type=nil
		@durPerReq=Array.new
		@sizePerReq=Array.new
	end
end
