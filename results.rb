
class User
        @@dPrices=Array.new
        @@ads=Array.new
        @@rows=Array.new
        @@imp=Array.new
	@@adBeacon=0
        @@paramNum=Array.new
        @@beacons=Array.new
        @@beaconType=Array.new
        @@sizes3rd=Array.new
        @@adsType={"adInUrl"=>0,"params"=>0,"imp"=>0,"mob"=>0}
        @@filterType={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0}

        def getPrices
                return @@dPrices
        end

	def getSizes
                return @@sizes3rd
        end

	def getBeacons
                return @@beacons, @@beaconType
        end

	def getImp_cnt
                return @@imp.length
        end

	def getLatency
                return @@filters.getLatency
        end

	def getAdResults
                return @@ads.size, @@adsType, @@filterType, @@adBeacon
        end

	
end
