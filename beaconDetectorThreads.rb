require 'sqlite3'
require 'fastimage'
require 'thread'
load 'define.rb'
load 'database.rb'

def is_1pixel_image?(url)
	return url if url==nil
	last=url.split("/").last
#	isthere=@db.get("beaconURLs","singlePixel","url",url)
#	if isthere!=nil		# I've already seen that url 
#		return (isthere.first.to_s == "1") if isthere.kind_of?(Array)
#		return (isthere.to_s == "1")
#	else	# no... wget it
		begin
			pixels=FastImage.size("http://"+url, :timeout=>2)
		    return pixels.to_s,url if pixels!=nil
		rescue Exception => e  
			if not e.message.include? "Network is unreachable"
				puts "is_1pixel_image: "+e.message+"\n"+url  
#				@db.insert("beaconURLs",[url,0])
			end
		end				
#	end			
    return nil,url
end

def store(line,filename)
	fw=File.new(filename+"beaconDetectorTHREADS.csv","a")
	fw.puts filename+"\t"+line.to_s
	fw.close
end

def offload()
	while @results.size>0
		pixels,url=@results.pop
		if pixels!=nil
			@count+=1 if pixels=="[1, 1]"
		else
			pixels="-1"
		end
		res="lala"
		res=@db.insertBEACON("beaconURLs",[pixels,url]) if url!=nil
		@dictionary[url]=pixels
	#	puts pixels+" "+url.to_s+" "+res.to_s
	end
end

startScript=Time.now
filename=ARGV[0]
@defines=Defines.new(filename.gsub("BEACONS_",""))
dbname=filename.rpartition("/")[0]+"beaconsDB.db"
@db = Database.new(@defines,dbname)
@db.create("beaconURLs",'imageSize VARCHAR, url VARCHAR PRIMARY KEY')
results=@db.getAll("beaconURLs",nil,nil,nil,true)
@dictionary=Hash.new
for res in results
	@dictionary[res["url"]]=res["imageSize"]
end
puts "Loaded previous snapshot of "+@dictionary.size.to_s+" elements"
#system("rm -f "+filename+"beaconDetectorTHREADS.csv")
f=File.new(filename)
totalLines= `wc -l "#{filename}"`.strip.split(' ')[0]
@count=0
h=Hash.new
threads=[]
@results=[]
while line=f.gets
	next	if h[line.chop]!=nil	
	h[line.chop]=true
end
f.close
total=0
found=0
start=Time.now
h.keys.each{|url|
	if @dictionary!=nil and @dictionary[url]!=nil
		found+=1
		next
	end
	begin
	threads.push(Thread.new{  
		@results.push(is_1pixel_image?(url))
	})
	rescue ThreadError => e
		puts "ThreadError "+e.to_s+"\n"+total.to_s+" lines"
		while threads.size>0
			thr=threads.pop
			thr.join
		end
		#try again
		threads.push(Thread.new{  
			@results.push(is_1pixel_image?(url))
		})		
	end
	total+=1
	if threads.size==10
		puts "\t"+total.to_s+"/"+totalLines+" lines so far... "+(Time.now - start).to_s+" seconds" 			
		while threads.size>0
			thr=threads.pop
			thr.join
		end
		start=Time.now
		offload()
	end
}
while threads.size>0
	thr=threads.pop
	thr.join
end
offload()
puts "THREADS, I found "+@count.to_s+" Beacons from "+total.to_s+" examined URLs from "+totalLines.to_s+" lines of "+filename
puts "Already found: "+found.to_s
store(@count,filename)
puts "Finished in "+(Time.now - startScript).to_s+" seconds"
