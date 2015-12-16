require 'user'

class Trace
	attr_accessor :rows, :mobDev, :adDevice, :users, :prices

	def initialize
		@rows=Array.new
		@mobDev=0
        	@adDevice=0
		@users=Hash.new
		@numOfImps=-1
		@totalParamNum=Array.new
		@prices=Array.new
		@sizes=Array.new
	end

	def sumUsersVariables
		sumAdB=0;sumImps=0;sumB=0;sumOfAds=0;sumOfMAd=0
		for user in @users.values do
			@totalParamNum+=user.paramNum
			@prices+=user.dPrices
			@sizes+=user.sizes3rd
			sumB+=user.beacons.size
			sumAdB+=user.adBeacon
			sumImps+=user.imp.size
			sumOfAds+=user.ads.size
			sumOfMAd+=user.mobAds
#TODO sum hashtables
		end
		sums=Hash.new
		sums['numOfBeacons']=sumB
		sums['numOfAdBeacons']=sumAdB
		sums['numOfImps']=sumImps
		sums['numOfAds']=sumOfAds
		sums['numOfAdMobile']=sumOfMAd
		return sums
	end

	def analyzeTotalAds    #Analyze global variables
		utils=Utilities.new
		utils.countInstances(@@paramsNum)
		utils.countInstances(@@devices)
		utils.countInstances(@@size3rdFile)
		sums=sumUsersVariables()
		return utils.makeStats(@totalParamNum),utils.makeStats(@sizes),sums
	end
end
