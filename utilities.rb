module Utilities

	def Utilities.loadOptions(configFile,files,tables)
		if File.exists? (configFile)
			return Utilities.readConfigFile(configFile),"> Config file was read..."
		else	# DEFAULT
			return Utilities.produceConfigFile(configFile,files,tables),"> No config file found... Default options are used..."
		end
	end	

	def Utilities.median(array)
  		sorted = array.sort
  		len = sorted.length
		return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
	end

    def Utilities.is_float?(object)
        if (not object.include? "." or object.downcase.include? "e") #out of range check
            return false
        else
            return Utilities.is_numeric?(object)
        end
    end
	
	def Utilities.printCatFileTypes(cat,c,user)
		s=""
		if user.fileTypes[cat]==nil
			for i in 0...9 do
				s+="0\t"
			end
			return s;
		end
		if user.fileTypes[cat].size!=0
			user.fileTypes[cat].each{|type, bytes|
				if bytes==nil or bytes.size==0
					s+="0\t"
				else			
					res=Utilities.makeStats(bytes); 
					if c==1 
						s+=res['sum'].to_s+"\t"
					else
						s+=bytes.size.to_s+"\t"
					end
				end };
		else
			for i in 0...9 do
				s+="0\t"
			end
		end
		return s
	end


	def Utilities.individualSites(file,traceFile,user,sumSizePerCat,avgDurPerCat,cats)
		if not File.exist? file and file!=nil
			fw=File.new(file,"w")
			fw.puts "site\tReqs:Advertising\tReqs:Analytics\tReqs:Social\tReqs:Content" +
#"\tReqs:Beacons" +
"\tReqs:Other\tTotalNumOfReqs\tAvgTimePerReq:Advertising\tAvgTimePerReq:Analytics\tAvgTimePerReq:Social\tAvgTimePerReq:Content" + 
#\tAvgTimePerReq:Beacons" +
"\tAvgTimePerReq:Other\tTotalBytes:Advertising\tTotalBytes:Analytics\tTotalBytes:Social\tTotalBytes:Content" +
#\tTotalBytes:Beacons" +
"\tTotalBytes:Other\tReqs:Advertising:data\tReqs:Advertising:gif\tReqs:Advertising:html\tReqs:Advertising:image\tReqs:Advertising:other\tReqs:Advertising:script\tReqs:Advertising:styling\tReqs:Advertising:text\tReqs:Advertising:video\tReqs:Analytics:data\tReqs:Analytics:gif\tReqs:Analytics:html\tReqs:Analytics:image\tReqs:Analytics:other\tReqs:Analytics:script\tReqs:Analytics:styling\tReqs:Analytics:text\tReqs:Analytics:video\tReqs:Social:data\tReqs:Social:gif\tReqs:Social:html\tReqs:Social:image\tReqs:Social:other\tReqs:Social:script\tReqs:Social:styling\tReqs:Social:text\tReqs:Social:video\tReqs:Content:data\tReqs:Content:gif\tReqs:Content:html\tReqs:Content:image\tReqs:Content:other\tReqs:Content:script\tReqs:Content:styling\tReqs:Content:text\tReqs:Content:video" +
#"\tReqs:Beacons:data\tReqs:Beacons:gif\tReqs:Beacons:html\tReqs:Beacons:image\tReqs:Beacons:other\tReqs:Beacons:script\tReqs:Beacons:styling\tReqs:Beacons:text\tReqs:Beacons:video" +
"\tReqs:Other:data\tReqs:Other:gif\tReqs:Other:html\tReqs:Other:image\tReqs:Other:other\tReqs:Other:script\tReqs:Other:styling\tReqs:Other:text\tReqs:Other:video\tTotalBytes:Advertising:data\tTotalBytes:Advertising:gif\tTotalBytes:Advertising:html\tTotalBytes:Advertising:image\tTotalBytes:Advertising:other\tTotalBytes:Advertising:script\tTotalBytes:Advertising:styling\tTotalBytes:Advertising:text\tTotalBytes:Advertising:video\tTotalBytes:Analytics:data\tTotalBytes:Analytics:gif\tTotalBytes:Analytics:html\tTotalBytes:Analytics:image\tTotalBytes:Analytics:other\tTotalBytes:Analytics:script\tTotalBytes:Analytics:styling\tTotalBytes:Analytics:text\tTotalBytes:Analytics:video\tTotalBytes:Social:data\tTotalBytes:Social:gif\tTotalBytes:Social:html\tTotalBytes:Social:image\tTotalBytes:Social:other\tTotalBytes:Social:script\tTotalBytes:Social:styling\tTotalBytes:Social:text\tTotalBytes:Social:video\tTotalBytes:Content:data\tTotalBytes:Content:gif\tTotalBytes:Content:html\tTotalBytes:Content:image\tTotalBytes:Content:other\tTotalBytes:Content:script\tTotalBytes:Content:styling\tTotalBytes:Content:text\tTotalBytes:Content:video" +
#"\tTotalBytes:Beacons:data\tTotalBytes:Beacons:gif\tTotalBytes:Beacons:html\tTotalBytes:Beacons:image\tTotalBytes:Beacons:other\tTotalBytes:Beacons:script\tTotalBytes:Beacons:styling\tTotalBytes:Beacons:text\tTotalBytes:Beacons:video" +
"\tTotalBytes:Other:data\tTotalBytes:Other:gif\tTotalBytes:Other:html\tTotalBytes:Other:image\tTotalBytes:Other:other\tTotalBytes:Other:script\tTotalBytes:Other:styling\tTotalBytes:Other:text\tTotalBytes:Other:video"
		else
			fw=File.new(file,"a")
		end		
		reqs="";str="";totalReqs=0
		cats.each{|cat|  totalReqs+=user.size3rdparty[cat].size; reqs+=user.size3rdparty[cat].size.to_s+"\t"} 
		if traceFile!=nil
			str=traceFile+"\t"
		end
		str+=reqs+totalReqs.to_s+"\t"
		str+=avgDurPerCat.gsub(",","\t").gsub("[","").gsub("]","")+"\t"+sumSizePerCat.gsub(",","\t").gsub("[","").gsub("]","").to_s+"\t"
		fileTypesStr=Utilities.printFileTypeAnalysis(cats,user)
		fw.puts str+fileTypesStr
		fw.close
		return str
	end

	def Utilities.printFileTypeAnalysis(cats,user)
		str=""
		cats.each{|cat| 
			str+=Utilities.printCatFileTypes(cat,0,user)
		}
		cats.each{|cat| 
			str+=Utilities.printCatFileTypes(cat,1,user)
		}
		return str
	end

	def Utilities.perUserEventSeparation(defines)
		fr=File.new(defines.dirs['dataDir']+"IPport_uniq")
		u=Hash.new()
		while line=fr.gets
			user=line.chop
			IO.popen('grep '+user+' ./'+defines.traceFile) { |io| 
			while (line = io.gets) do 
				h=Format.columnsFormat(line,defines.column_Format)
				separateTimelineEvents(h)
				u[h['IPport']]=h['url']
			end }
		end
		fr.close
		return u
	end	

	def Utilities.separateTimelineEvents(row,writeTo,dataset)
		fp=File.new(writeTo,'a')
		if dataset==1
			fp.puts(row['IPport']+"\t"+row['uIP'].to_s+"\t"+row['url']+"\t"+row['ua']+"\t"+row['host']+"\t"+row['tmstp']+"\t"+
				row['status']+"\t"+row['length']+"\t"+row['dataSz']+"\t"+row['dur'])
		elsif dataset==2
			fp.puts("\t-\t"+row['uIP']+"\t"+row['tmstp']+"\t"+row['status']+"\t"+row['length']+"\t"+row['dataSz']+"\t"+
            row['dur']+"\t-\t"+row['IPport']+"\t"+row['verb']+"\t-\t"+row['url']+"\t-\t"+row['ua']+"\t"+row['host'])
		else
			Utilities.error("Wrong column format... Check input!")
		end
		fp.close
	end

	def Utilities.prepareParam(paramVal)
		res=paramVal
		if res.include? "%"
			tmp=res.split "%"
			res=tmp.first
			return nil if res==""
		end
		if res.include? "//"
			res=res.split("//").last
		end	
		if res.include? "/"
			tmp=res.split "/"
			res=tmp.first
		end
		if res.include? "&"
			tmp=res.split "&"
			res=tmp.first
		end	
		res=res.gsub(",","")		
		return res.split(".").first	if (res.include? "." and res.split(".").last.size>4 and res.split(".").size<3 and res.split(".").size>1)
		return res
	end

	def Utilities.calculateHost(uri,host)
		return -1 if uri==-1 or uri==nil or uri=="" or uri==" "
		url=URI.unescape(uri.force_encoding("ISO-8859-1"))
		firstPart=url.split("?").first
		if firstPart.include? "www." and not firstPart.include? "/www./"
			temp=firstPart.split("www.")
			firstPart=temp.last
		end
		firstPart=firstPart.split("/").first.gsub("%20","")	if firstPart.include? "/"#.split("%")
		if firstPart.include? "http"
			firstPart=firstPart.split("://").last
		end
		firstPart=firstPart.split("#") if firstPart.include? "#"
		firstPart=firstPart.first if firstPart.kind_of?(Array) and firstPart.size>1
		firstPart=firstPart.split(":").first if firstPart.include? ":"
		temp=firstPart.split(".")
		if temp.size>1
			if Utilities.is_numeric?(temp[temp.size-2]) and Utilities.is_numeric?(temp[temp.size-1])	#ip case
				return firstPart
			elsif (url.include? 'org.es' or url.include? 'co.jp' or url.include? 'com.uy' or url.include? 'com.mx' or url.include? 'com.mk' or url.include? 'edu.mx' or url.include? 'com.es' or url.include? 'com.ar' or url.include? 'com.do' or url.include? 'co.uk' or url.include? 'co.in' or url.include? 'com.br' or url.include? 'com.au' or url.include? 'org.br' or url.include? 'uk.com' or url.include? 'co.nz' or url.include? 'co.id' or url.include? 'co.kr')
				return temp[temp.size-3]+"."+temp[temp.size-2]+"."+temp[temp.size-1]
			else
				return temp[temp.size-2]+"."+temp[temp.size-1]
			end
		else
			if host!=nil
				return host
			else
				return temp.first
			end
		end
	end

	def Utilities.tokenizeHost(host)
		parts=host.split(".")
		if (host.include? 'org.es' or host.include? 'co.jp' or host.include? 'com.uy' or host.include? 'com.mx' or host.include? 'com.mk' or host.include? 'edu.mx' or host.include? 'com.es' or host.include? 'com.ar' or host.include? 'com.do' or host.include? 'co.uk' or host.include? 'co.in' or host.include? 'com.br' or host.include? 'com.au' or host.include? 'org.br' or host.include? 'uk.com' or host.include? 'co.nz' or host.include? 'co.id' or host.include? 'co.kr')
			tld=parts[parts.size-2]+"."+parts[parts.size-1]
            domain=parts[parts.size-3]
		else
            tld=parts[parts.size-1]
            domain=parts[parts.size-2]
        end
		return domain,tld
	end

	def Utilities.makeStats(arr)
		result={'sum'=>0,'avg'=>0,'median'=>0,'max'=>0,'min'=>0}
		if arr!=nil and arr.length>0
			result['sum']=arr.inject{ |s, el| s + el}.to_f
			result['avg']=result['sum']/arr.size
		#	result['median']=median(arr)
			result['min']=arr.min
			result['max']=arr.max
		end
		return result
	end

    def Utilities.is_numeric?(object)
       	if object==nil
        	return false
        end
        true if Float(object) rescue false
    end

	def Utilities.warning(str)
		STDERR.puts "---> "+caller[0][/`([^']*)'/, 1]+": WARNING: "+str
	end

	def Utilities.error(str)
		abort "---> "+caller[0][/`([^']*)'/, 1]+": ERROR: "+str
	end

	def Utilities.printRowToDB(row,db,table,extra)
		if db!=nil
			id=""
			if (row['httpRef']!=-1)
				id=Digest::SHA256.hexdigest (row.values.join("|")+"|"+row['httpRef'])
			else
				id=Digest::SHA256.hexdigest (row.values.join("|"))
			end
			params=[id,row['tmstp'],row['IPport'],row['uIP'],row['url'],row['host'],row['ua'],row['status'],row['length'],row['dataSz'],
									row['dur'],row['mob'],row['dev'],row['browser']]
			if extra!=nil
				params.push(extra)
			end
			db.insert(table,params)
		end
	end

   	def Utilities.stripper(str)
       if (str==nil)
           return ""
       end
       parts=str.split('&')
       s=""
       for param in parts do
           s=s+"->\t"+param+"\n"
       end
       return s
   	end

   	def Utilities.printStrippedURL(url,fw)
		if fw!=nil
			params=Utilities.stripper(url[1])
	        fw.puts "\n"+url[0]+" "
	        if params!=""
	            fw.puts params
	        else
	            fw.puts "----"
	       	end
		end
    end

    def Utilities.makeDistrib_LaPr(adsDir)            # Calculate Latency and Price distribution
        countInstances("./","latency.out")        #latency
        system("awk \'{print $2\" \"$1}\' "+adsDir+"prices | sort -n | uniq -c | sort -n | tac > "+adsDir+"prices_cnt")
        system("awk \'{print $2\" \"$1}\' "+adsDir+"prices | sort -n | uniq > "+adsDir+"prices_uniq")
    end

	def Utilities.printRow(row,fw)
		if fw!=nil
			for key in row.keys
	        	fw.puts key+" => "+row[key]
				if key=="url"
					Utilities.printStrippedURL(row[key].split('?'),fw)
				end
	     	end
	        fw.puts "------------------------------------------------"
	    end
	end

	def Utilities.countInstances(file)
		if (file!=nil and File.exists?(file))
			if file.include? "devices"
				system("cat "+file+" | awk '{print $3}' | sort -g | uniq -c | sort -rg  > "+file+"_cnt") #calculate distribution
			else
	        	system('sort -g '+file+' | uniq -c | sort -rg  > '+file+"_cnt") #calculate distribution
			end
		end	
	end

	def Utilities.readConfigFile(configFile)
       	file = File.read(configFile)
       	options = JSON.parse(file)
		return options
	end

	def Utilities.digitAlfa(str)
		alfas=0; digits=0
		return -1,-1 if str==nil
		str.chars.each{|c| 
			if Utilities.is_numeric?(c) 
				digits+=1; 
			else 
				alfas+=1; 
			end}
		return alfas,digits
	end


	def Utilities.produceConfigFile(configFile,files,tables)
		defaultOptions={"mobileOnly?"=>false,"isThereHeader?"=>true,"removeDuplicates?"=>true,"printToSTDOUT?"=>true, "detectBeacons?"=>true,"webVsApp?"=>false,
			'resultToFiles'=>{files[0]=>false, files[1]=>false,
			files[2]=>false, files[3]=>false,files[4]=>false,files[5]=>false},"database?"=>true,
			'tablesDB'=>{tables["publishersTable"].keys[0]=>false, tables["bcnTable"].keys[0]=>false,
			tables["impTable"].keys[0]=>false, tables["bcnTable"].keys[0]=>true,
			tables["adsTable"].keys[0]=>true, tables["userTable"].keys[0]=>true,
			tables["priceTable"].keys[0]=>true,	tables["traceTable"].keys[0]=>true,
			tables["csyncTable"].keys[0]=>true,tables["visitsTable"].keys[0]=>false,tables["userFilesTable"].keys[0]=>false,
			tables["advertiserTable"].keys[0]=>true}}
		File.open(configFile,"w") do |f|
		  f.write(JSON.pretty_generate(defaultOptions, :indent => "\t"))
		end
		return defaultOptions
	end
end
