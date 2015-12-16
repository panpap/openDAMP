
class User
	attr_accessor :dPrices, :sizes3rd, :imp, :latency, :ads, :adBeacon, :filterType, :adsType, :beacons, :paramNum, :mobAds

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
		@mobAds=0
		@filterType={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0}
	end
end
