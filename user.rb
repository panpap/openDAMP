
class User
	attr_accessor :dur3rd, :csync, :publishers, :numericPrices, :hashedPrices, :size3rdparty, :sizes3rd, :imp, :latency, :ads, :adBeacon, :filterType, :adsType

	def initialize
		@hashedPrices=Array.new
		@numericPrices=Array.new
		@ads=Array.new
	#	@rows=Array.new
		@imp=Array.new
	#	@beacons=Array.new
		@adBeacon=0
		@csync=Array.new
		@publishers=Array.new
	#	@row3rdparty={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
		@size3rdparty={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
		@dur3rd={"Advertising"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
	end
end
