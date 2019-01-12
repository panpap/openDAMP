require "date"

module Format

	def Format.columnsFormat(line,dataset,option,filter)
		return nil if line.include? "/awazzaredirect/" # Duplicate removal
		begin
			part=line.chop.split("\t") 
		rescue 
			part=line.chop.force_encoding("iso-8859-1").split("\t")
		end
		h=Hash.new(-1)
		if dataset==1
			#IP_Port	UserIP	URL	UserAgent	Host	Timestamp	ResponseCode	ContentLength	DeliveredData	Duration	HitOrMiss
			h['IPport']=part[0].split(":").last
		    h['uIP']=part[1]
		    h['url']=part[2]
			if h['url']==nil
				Utilities.warning "EMPTY URL: "+line
				return nil
			end
		    h['ua']=part[3]
			h['host']=Utilities.calculateHost(h['url'],part[4])
			if h['host']==nil
				Utilities.warning "ERROR IN HOST: "+line
				return nil
			end
			h['type']=filter.getTypeOfContent(h['url'],nil)
		    h['tmstp']=part[5]
		    h['status']=part[6]
		    h['length']=part[7]
		    h['dataSz']=part[8]
		    h['dur']=part[9]
			h['mob']=nil
			h['browser']=-1
			h['device']=nil
			h['httpRef']=-1
		elsif dataset==2
			#id	NodeIP	UserIP	Timestamp	ResponseCode	ContentLength	DeliveredData	Duration	HitOrMiss	PortNumber	HTTP_Verb	ToCrawl	Path	HTTPReferer	UserAgent	Host	Cookie	OrigReq	ToCrawl_v2	ContentType
			h['uIP']=part[2]
            h['tmstp']=part[3]
            h['status']=part[4]
            h['length']=part[5]
            h['dataSz']=part[6]
            h['dur']=part[7]
			h['IPport']=part[9].split(":").last
			h['verb']=part[10]
			h['host']=part[15].split("://").last
			return nil if h['host']==nil
			h['mob']=nil
			h['browser']=-1
			h['httpRef']=part[13]
			h['device']=nil
			if (["get","delete","put","post","head","options"].any? { |word| h['verb'].downcase.eql?(word)})
				h['url']=h['host']+part[12]	#host+path
			elsif h['verb'].downcase=="connect" 
				h['url']=part[12].split("://").last
			else
				Utilities.warning  "--------> UKNOWN HTTP VERB: "+h['verb']
			end
			return nil if h['url'].size<4
			h['type']=filter.getTypeOfContent(h['url'],nil)
            h['ua']=part[14]	
	
		elsif dataset==3
#-	nodeIP	userIP	-	verb	url	httpref	HttpStatus	length	dataSz	duration	-	useragent	host	-	type	userID	timestamp	country
			h['IPport']=(part[1]+":"+part[16]).split(":").last
			h['uIP']=part[2]
			h['verb']=part[4]
			if not( ["get","delete","put","post","head","options"].any? { |word| h['verb'].downcase.eql?(word)})	# remove HTTPS
				return nil
			end
			h['host']=part[13].gsub(":80","")
			if h['host'].include? ".." or h['host']=="" or h['host']=="." or h['host'].size<3 or h['host'].include? "??" or part[5]=="/" or h['host']=="www."
				return nil
			end
			h['httpRef']=part[6]
			h['status']=part[7]
			h['length']=part[8]
		    h['dataSz']=part[9]
 			h['dur']=part[10]
			h['ua']=part[12]
			h['tmstp']=part[17]
			if (["get","delete","put","post","head","options"].any? { |word| h['verb'].downcase.eql?(word)})
				h['url']=h['host']+part[5]	#host+path
			elsif h['verb'].downcase=="connect" 
				h['url']=part[5].split("://").last
			else
				Utilities.warning  "--------> UKNOWN HTTP VERB: "+h['verb']
			end
			h['types']=filter.getTypeOfContent(h['url'],part[15])
		else
			h['uIP']=part[2]
			h['url']=part[4]
		#	if part[2].include? "http"
		#		h['url']=part[2].split("://").last
		#	end
			h['host']=part[5]
			h['host']=Utilities.calculateHost(h['url'],part[5]) if h['host']==nil or h['host'].size<2
			h['type']=filter.getTypeOfContent(h['url'],nil)
			h['tmstp']=part[8]
			h['tmstp']=DateTime.rfc3339(part[8]).to_time.to_i if part[8].include?(":").to_s
			h['httpRef']=part[6]
			h['status']="-"
			h['cookie']=part[7]
			#Utilities.error("Wrong column format... File cannot be read!")
		end
		return h
	end
end
