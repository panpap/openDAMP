
class User
	attr_accessor :dPrices, :row3rdparty, :adNumOfParams, :sizes3rd, :imp, :latency, :ads, :adBeacon, :filterType, :adsType, :restNumOfParams

	def initialize
		@dPrices=Array.new
		@ads=Array.new
		@rows=Array.new
		@imp=Array.new
		@adBeacon=0
		@restNumOfParams=Array.new
		@adNumOfParams=Array.new
		@sizes3rd=Array.new
		@adsType={"adInUrl"=>0,"params"=>0,"imp"=>0}
		@row3rdparty={"Advertising"=>[],"AdExtra"=>[],"Beacons"=>[],"Social"=>[],"Analytics"=>[],"Content"=>[],"Other"=>[]}
	end
end
