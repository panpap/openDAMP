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
			url="http://"+url if not url.include? "://"
			pixels=FastImage.size(url, :timeout=>2)
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


filename=ARGV[0]
@defines=Defines.new(filename.gsub("BEACONS_",""))
dbname=filename.rpartition("/")[0]+"beaconsDB.db"
@db = Database.new(@defines,dbname)
#if not File.file?(dbname)
	@db.create("beaconURLs",'imageSize VARCHAR, url VARCHAR PRIMARY KEY')
#end
system("rm -f "+filename+"beaconDetectorTHREADS.csv")
f=File.new(filename)
total=0
totalLines= `wc -l "#{filename}"`.strip.split(' ')[0]
@count=0
h=Hash.new
start=Time.now
threads=[10]
results=[10]
while line=f.gets
	begin
		next	if h[line.chop]!=nil	
		h[line.chop]=true
		#puts line.chop+"\typarxei?\t"+@db.get("beaconURLs","imageSize","url",line.chop).to_s
		next	if @db.get("beaconURLs","imageSize","url",line.chop)!=nil
		threads[total]=Thread.new{ 
			puts is_1pixel_image?(line.chop)[1]
			Thread.exit}
		total+=1
		if threads.size==10
			total=0
			for thr in threads
				thr.join
for cell in results
puts cell.to_s
end
			end



abort













			while threads.size>0
				t=threads.pop		
				pixels,url=t[:output]
				if pixels!=nil
					@count+=1 if pixels=="[1, 1]"
				else
					pixels="-1"
				end
				res="lala"
				res=@db.insertBEACON("beaconURLs",[pixels,url]) if url!=nil
				puts pixels+" "+url.to_s+" "+res.to_s
			end
			puts "\t"+total.to_s+"/"+totalLines+" lines so far... "+(Time.now - start).to_s+" seconds"
			start=Time.now
		end
	rescue ThreadError => e
		puts "ThreadError "+e.to_s+"\n"+total.to_s+" lines"
		while threads.size>0
			t=threads.pop
			t.join
			pixels,url=t[:output]
			if pixels!=nil
				@count+=1 if pixels=="[1, 1]"
			else
				pixels="-1"
			end
			@db.insertBEACON("beaconURLs",[pixels,url]) if url!=nil
		end
	end
end
while threads.size>0
	t=threads.pop
	t.join
	pixels,url=t[:output]
	if pixels!=nil
		@count+=1 if pixels=="[1, 1]"
	else
		pixels="-1"
	end
	@db.insertBEACON("beaconURLs",[pixels,url]) if url!=nil
end
f.close
puts "THREADS, I found "+@count.to_s+" Beacons out of "+total.to_s+" examined URLs for "+filename
store(@count,filename)
