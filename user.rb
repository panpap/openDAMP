
class User
	attr_accessor :dur3rd, :csync, :fileTypes, :publishers, :numericPrices, :hashedPrices, :size3rdparty, :sizes3rd, :imp, :latency, :ads

	def initialize
		@hashedPrices=Array.new
		@numericPrices=Array.new
		@ads=Array.new
		@imp=Array.new
	#	@beacons=Array.new
		@csync=Array.new
		@publishers=Array.new
		@size3rdparty={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
		@dur3rd={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
		@fileTypes={"Advertising"=>nil,"Social"=>nil,"Analytics"=>nil,"Content"=>nil, "Other"=>nil, "Beacons"=>nil}
	end
end
