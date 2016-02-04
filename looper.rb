root="sites-without-adblock/"
countries=Dir.countries(root) rescue countries=Array.new
for country in countries
	puts "Country: "+country
	sites=Dir.sites(root+country) rescue sites=Array.new
	for file in sites
		if file.include? ".out"
			puts "Processing "+file+" from "+country
			name=country+"_"+file.split(".")[0]
			system("ruby parser -o "+root+country+"/"+file+" > /results_"+name+"/"+name+"_outFile")
			system("ruby parser -p "+root+country+"/"+file+" > groupDir/results_"+name+"/"+name+"_outFile")
		end
	end
end
