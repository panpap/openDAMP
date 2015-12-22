load 'user.rb'

class Trace
	attr_accessor :rows, :mobDev, :numOfMobileAds, :totalAdBeacons, :totalImps, :users, :detectedPrices, :party3rd, :sizes, :totalParamNum

	def initialize(defs)
		@defines=defs
		@rows=Array.new
		@mobDev=0
		@users=Hash.new
		@totalParamNum=Array.new
		@detectedPrices=Array.new
		@sizes=Array.new
		@totalImps=0
		@totalAdBeacons=0
		@numOfMobileAds=0
		@party3rd={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0, "Other"=>0, "totalBeacons"=>0}
	end

	def analyzeTotalAds    #Analyze global variables
		Utilities.countInstances(@defines.paramsNum)
		Utilities.countInstances(@defines.devices)
		Utilities.countInstances(@defines.size3rdFile)
		return Utilities.makeStats(@totalParamNum),Utilities.makeStats(@sizes)
	end
end
