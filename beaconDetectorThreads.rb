require 'sqlite3'
require 'fastimage'
require 'thread'
load 'define.rb'
load 'database.rb'

def is_1pixel_image?(url)
	abort "NULL URL" if url==nil
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
puts @results.size.to_s+" results"
	while @results.size>0
		result=@results.pop
		pixels=result[0]
		url=result[1]
		res=result[2]
abort "NULL url "+@results.size if url==nil
		if pixels!=nil
			@count+=1 if pixels=="[1, 1]"
		else
			pixels="-1"
		end
abort "NULL user "+@results.size if res['IPport']==nil
		@db.insertBEACON("beacons",[pixels,url,res['IPport'],res['uIP'],res['host'],res['httpRef'],res['status'],res['dataSz'],res['dur'],res['ua'],res['tmstp'],res['type'],res['mob'],res['dev'],res['browser']]) if url!=nil
		@dictionary[url]=pixels
	#	puts pixels+" "+url.to_s+" "+res.to_s
	end
end

startScript=Time.now
filename=ARGV[0]
@defines=Defines.new(filename.gsub("BEACONS_",""))
dbname=filename.rpartition("/")[0]+"/beaconsChecked_"+filename.gsub("BEACONS_".rpartition("/")[1]+"+.db"
min,max=Process.getrlimit(Process::RLIMIT_NOFILE)
puts "Initial open sockets boundaries: ["+min.to_s+","+max.to_s+"]"
puts "Stretching the number of simultaneously open sockets"
Process.setrlimit(Process::RLIMIT_NOFILE,max,max)
socketsLimit=Process.getrlimit(Process::RLIMIT_NOFILE)
puts "Now I can open no more than "+(max/1000*1000).to_s+" sockets simultaneously"
@db = Database.new(@defines,dbname)
@db.create("beacons",'imageSize VARCHAR, url VARCHAR PRIMARY KEY,user VARCHAR, userIP VARCHAR, host VARCHAR, httpRef VARCHAR, status VARCHAR, dataSz VARCHAR, dur VARCHAR, ua VARCHAR, tmstp VARCHAR, type VARCHAR, mob VARCHAR, dev VARCHAR, browser VARCHAR')
results=@db.getAll("beacons",nil,nil,nil,true)
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
threads=Queue.new
@results=Queue.new
while line=f.gets
	next	if h[line.chop]!=nil
	newHash=Hash.new
	url=nil
	line.split(', "').each{
		|part| parts=part.gsub("}","").gsub("\n","").gsub("{","").gsub('" ',"").gsub("\"","").split("=>")
		if parts.first=="url"
			url=parts.last
		else
			newHash[parts.first]=parts.last
		end		
	}
	abort "WRONG! NULL URL" if url==nil
	h[url]=newHash
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
		pixel,urlChecked=is_1pixel_image?(url)
		@results.push([pixel,urlChecked,h[url]])
	})
	rescue ThreadError => e
		puts "ThreadError "+e.to_s+"\n"+total.to_s+" lines"
		while threads.size>0
			thr=threads.pop
			thr.join
		end
		#try again
		threads.push(Thread.new{  
			pixel,urlChecked=is_1pixel_image?(url)
			@results.push([pixel,urlChecked,h[url]])
		})		
	end
	total+=1
	if threads.size==(max/1000*1000)
		puts "\t"+total.to_s+"/"+totalLines+" lines so far... "+(Time.now - start).to_s+" seconds"
		print threads.size.to_s+" threads"
		while threads.size>0
			thr=threads.pop
			thr.join
		end		
		offload()
		start=Time.now
	end
}
while threads.size>0
	thr=threads.pop
	thr.join
end
offload()
puts "\n-------------RESULTS-------------\n I found "+@count.to_s+" Beacons from "+total.to_s+" examined URLs from "+totalLines.to_s+" lines of "+filename
puts "Already found: "+found.to_s
store(@count,filename)
puts "Finished in "+(Time.now - startScript).to_s+" seconds"
