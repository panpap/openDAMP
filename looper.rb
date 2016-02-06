root=ARGV[0]
Dir.mkdir "outsDir/" unless File.exists?("outsDir/")
puts "Give proper input" if root==nil
countries=Dir.entries(root) rescue countries=Array.new
for country in countries
        puts "Country: "+country
        sites=Dir.entries(root+country) rescue sites=Array.new
        for file in sites
                if file.include? ".out"
                        puts "Processing "+file+" from "+country
                        name=country+"_"+file.split(".")[0]
                        system("ruby parser.rb -o "+root+country+"/"+file)
                end
        end
	puts sites.size.to_s+" sites were processed"
end
puts countries.size.to_s+" country folders were parsed"
system("mv outsDir/ groupDir/")

