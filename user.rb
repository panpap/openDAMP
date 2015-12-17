
class User
	attr_accessor :dPrices, :row3rdparty, :sizes3rd, :imp, :latency, :ads, :adBeacon, :filterType, :adsType, :beacons, :paramNum

	def initialize
		@dPrices=Array.new
		@ads=Array.new
		@rows=Array.new
		@imp=Array.new
		@adBeacon=0
		@paramNum=Array.new
		@beacons=Array.new
		@sizes3rd=Array.new
		@adsType={"adInUrl"=>0,"params"=>0,"imp"=>0}
		@filterType={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0}
		@row3rdparty={"Advertising"=>[],"AdExtra"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
	end
end
