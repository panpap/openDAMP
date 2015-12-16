require 'user'

class Trace
	attr_reader :rows :detPrices :mobDev :devices :users

	def initialize
		@rows=Array.new
		@mobDev=0
        @adDevice=Array.new
		@device=Array.new
		@users=Hash.new
		@detPrices=-1
		@numOfImps=-1
		@totalParamNum=Array.new
		@prices=Array.new
		@sizes=Array.new
	end

	def sumUsersVariables
		sumAdB=0;sumImps=0;sumB=0;sumOfAds=0;sumOfMAd=0
		for user in @users do
			@totalParamNum+=user.paramNum
			@prices+=user.dPrices
			@sizes+=user.sizes3rd
			sumB+=user.beacons.size
			sumAdB+=user.adBeacons
			sumImps+=user.imp.size
			sumOfAds+=user.ads.size
			sumOfMAd+=user.mobAds
#TODO sum hashtables
		end
		sums['numOfBeacons']=v
		sums['numOfAdBeacons']=sumAdB
		sums['numOfImps']=sumImps
		sums['numOfAds']=sumOfAds
		sums['numOfAdMobile']=sumOfMAd
		return sums
	end

	def analyzeTotalAds    #Analyze global variables
		@@utils.countInstances(@@paramsNum)
		@@utils.countInstances(@@devices)
		@@utils.countInstances(@@size3rdFile)
		sums=sumUsersVariables()
		return Utilities.makeStats(@totalParamNum),Utilities.makeStats(@sizes),sums
	end

end
