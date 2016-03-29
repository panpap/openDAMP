def processFile(file,folder,root)
    puts "Processing "+file+" from "+folder
    name=folder+"_"+file.split(".")[0]
    system("ruby parser.rb -o "+root+folder+"/"+file)
end


root=ARGV[0]
#Dir.mkdir "groupDir/" unless File.exists?("groupDir/")
puts "Give proper input" if root==nil
folders=Dir.entries(root).select {|f| f!="." and f!=".."} rescue folders=Array.new
sitesCrawled=0
threads=Array.new
for folder in folders
	sitesDir=Dir.entries(root+folder) rescue sitesDir=Array.new
	if sitesDir.size!=0
		for file in sitesDir.select {|f| f.include? ".csv" or f.include? ".out"}	
			if File.exist? (root+folder+"/"+file)
				processFile(file,folder,root)
				#t=Thread.new{processFile(file,folder,root)}
			#	threads.push(t)
				sitesCrawled+=1
			end
		end
	end 
end
#threads.each{|t| t.join}
puts sitesDir.size.to_s+" folders were parsed "+sitesCrawled.to_s+" sitesDir were processed"
