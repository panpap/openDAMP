module Format
	def Format.columnsFormat(part,dataset)
		h=Hash.new(-1)
		if dataset==1
			#IP_Port	UserIP	URL	UserAgent	Host	Timestamp	ResponseCode	ContentLength	DeliveredData	Duration	HitOrMiss
			h['IPport']=part[0]
		    h['uIP']=part[1]
		    h['url']=part[2]
		    h['ua']=part[3]
		    h['host']=part[4]
		    h['tmstp']=part[5]
		    h['status']=part[6]
		    h['length']=part[7]
		    h['dataSz']=part[8]
		    h['dur']=part[9]
		elsif dataset==2
			#id	NodeIP	UserIP	Timestamp	ResponseCode	ContentLength	DeliveredData	Duration	HitOrMiss	PortNumber	HTTP_Verb	ToCrawl	Path	HTTPReferer	UserAgent	Host	Cookie	OrigReq	ToCrawl_v2	ContentType
			h['IPport']=part[9]
			h['host']=part[15]
			h['verb']=part[10]
			if (["get","delete","put","post","head","options"].any? { |word| h['verb'].downcase.eql?(word)})
				h['url']=h['host']+part[12]	#host+path
			elsif h['verb'].downcase=="connect" 
				h['url']=part[12]
			else
				puts "--------> UKNOWN HTTP VERB: "+h['verb']
			end
            h['ua']=part[14]
            h['tmstp']=part[3]
            h['status']=part[4]
            h['length']=part[5]
            h['dataSz']=part[6]
            h['dur']=part[7]
		else
			abort("Error: Wrong column format... File cannot be read!")
		end
		return h
	end
end
