require 'sqlite3'
require 'fastimage'
require 'thread'

def is_1pixel_image?(url)
	return url if url==nil
	last=url.split("/").last
	#isthere=@db.get("beaconURLs","singlePixel","url",url)
#	if isthere!=nil		# I've already seen that url 
#		return (isthere.first.to_s == "1") if isthere.kind_of?(Array)
#		return (isthere.to_s == "1")
#	else	# no... wget it
		begin
			url="http://"+url if not url.include? "://"
			pixels=FastImage.size(url, :timeout=>5)
		    return pixels.to_s if pixels!=nil
		rescue Exception => e  
			if not e.message.include? "Network is unreachable"
				puts "is_1pixel_image: "+e.message+"\n"+url  
			#	@db.insert("beaconURLs",[url,0])
			end
		end				
#	end			
    return nil
end

def store(line)
	fw=File.new("beaconDetectorTHREADS.csv","a")
	fw.puts ARGV[0]+"\t"+line.to_s
	fw.close
end

system("rm -f beaconDetectorTHREADS.csv")
#@db = Database.new(@defines,"beaconsDB.db")
f=File.new(ARGV[0])
images=ARGV[0]+"THREADS_IMGsizes"
fw=File.new(images,"w")
total=0
@count=0
start=Time.now
threads=Array.new
while line=f.gets
	threads.push(Thread.new{ 
		#q.push(line)
			pixels=is_1pixel_image?(line)
			Thread.current[:output]=pixels,line if pixels!=nil
			Thread.exit})
	if total%1000==0
		puts "\t"+total.to_s+" lines so far... "+(Time.now - start).to_s+" seconds"
		start=Time.now
		sleep(7)
	end
	total+=1
end
for t in threads
	t.join
	pixels,url=t[:output]
	if pixels!=nil
		@count+=1 if pixels=="[1, 1]"
		params=0
		params=url.split("?")[1].split("&").size if url.split("?").size >1
		fw.puts pixels+"\t"+params.to_s+"\t"+url
	end
end
images= `wc -l "#{images}"`.strip.split(' ')[0].to_i
f.close
fw.close
puts "THREADS, I found "+@count.to_s+"/"+images.to_s+" Beacons out of "+total.to_s+" examined URLs for "+ARGV[0].split("BEACONS_")[1]
store(@count)
