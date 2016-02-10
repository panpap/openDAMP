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
	
	def Utilities.printCat(fw,cat,c,trace)
		if trace.fileTypes[cat]==nil
			for i in 0...9 do
				fw.print "0\t"
			end
			return;
		end
		if trace.fileTypes[cat].size!=0
			trace.fileTypes[cat].each{|type, bytes|
				if bytes==nil or bytes.size==0
					fw.print "0\t"
				else			
					res=Utilities.makeStats(bytes); 
					if c==1 
						fw.print res['sum'].to_s+"\t"
					else
						fw.print bytes.size.to_s+"\t"
					end
				end };
		else
			for i in 0...9 do
				fw.print "0\t"
			end
		end
	end


	def Utilities.individualSites(traceFile,user,sumSizePerCat,avgDurPerCat,trace)
		if not File.exist? "./sites.csv"
			fw=File.new("./sites.csv","a")
			fw.puts "site\tReqs:Advertising\tReqs:Analytics\tReqs:Social\tReqs:Content\tReqs:Beacons\tReqs:Other\t"+
					"AvgTimePerReq:Advertising\tAvgTimePerReq:Analytics\tAvgTimePerReq:Social\tAvgTimePerReq:Content\tAvgTimePerReq:Beacons\tAvgTimePerReq:Other\t"+
					"TotalBytes:Advertising\tTotalBytes:Analytics\tTotalBytes:Social\tTotalBytes:Content\tTotalBytes:Beacons\tTotalBytes:Other\t"+
					"Reqs:Advertising:data\tReqs:Advertising:gif\tReqs:Advertising:html\tReqs:Advertising:image\tReqs:Advertising:other\tReqs:Advertising:script\tReqs:Advertising:styling\tReqs:Advertising:text\tReqs:Advertising:video\t"+
		"Reqs:Analytics:data\tReqs:Analytics:gif\tReqs:Analytics:html\tReqs:Analytics:image\tReqs:Analytics:other\tReqs:Analytics:script\tReqs:Analytics:styling\tReqs:Analytics:text\tReqs:Analytics:video\t"+
		"Reqs:Social:data\tReqs:Social:gif\tReqs:Social:html\tReqs:Social:image\tReqs:Social:other\tReqs:Social:script\tReqs:Social:styling\tReqs:Social:text\tReqs:Social:video\t"+
		"Reqs:Content:data\tReqs:Content:gif\tReqs:Content:html\tReqs:Content:image\tReqs:Content:other\tReqs:Content:script\tReqs:Content:styling\tReqs:Content:text\tReqs:Content:video\t"+
		"Reqs:Beacons:data\tReqs:Beacons:gif\tReqs:Beacons:html\tReqs:Beacons:image\tReqs:Beacons:other\tReqs:Beacons:script\tReqs:Beacons:styling\tReqs:Beacons:text\tReqs:Beacons:video\t"+
		"Reqs:Other:data\tReqs:Other:gif\tReqs:Other:html\tReqs:Other:image\tReqs:Other:other\tReqs:Other:script\tReqs:Other:styling\tReqs:Other:text\tReqs:Other:video\t"+
		"TotalBytes:Advertising:data\tTotalBytes:Advertising:gif\tTotalBytes:Advertising:html\tTotalBytes:Advertising:image\tTotalBytes:Advertising:other\tTotalBytes:Advertising:script\tTotalBytes:Advertising:styling\tTotalBytes:Advertising:text\tTotalBytes:Advertising:video\t"+
		"TotalBytes:Analytics:data\tTotalBytes:Analytics:gif\tTotalBytes:Analytics:html\tTotalBytes:Analytics:image\tTotalBytes:Analytics:other\tTotalBytes:Analytics:script\tTotalBytes:Analytics:styling\tTotalBytes:Analytics:text\tTotalBytes:Analytics:video\t"+
		"TotalBytes:Social:data\tTotalBytes:Social:gif\tTotalBytes:Social:html\tTotalBytes:Social:image\tTotalBytes:Social:other\tTotalBytes:Social:script\tTotalBytes:Social:styling\tTotalBytes:Social:text\tTotalBytes:Social:video\t"+
		"TotalBytes:Content:data\tTotalBytes:Content:gif\tTotalBytes:Content:html\tTotalBytes:Content:image\tTotalBytes:Content:other\tTotalBytes:Content:script\tTotalBytes:Content:styling\tTotalBytes:Content:text\tTotalBytes:Content:video\t"+
		"TotalBytes:Beacons:data\tTotalBytes:Beacons:gif\tTotalBytes:Beacons:html\tTotalBytes:Beacons:image\tTotalBytes:Beacons:other\tTotalBytes:Beacons:script\tTotalBytes:Beacons:styling\tTotalBytes:Beacons:text\tTotalBytes:Beacons:video\t"+
		"TotalBytes:Other:data\tTotalBytes:Other:gif\tTotalBytes:Other:html\tTotalBytes:Other:image\tTotalBytes:Other:other\tTotalBytes:Other:script\tTotalBytes:Other:styling\tTotalBytes:Other:text\tTotalBytes:Other:video\t"
		else
			fw=File.new("./sites.csv","a")
		end
		fw.print traceFile+"\t"+user.size3rdparty['Advertising'].size.to_s+"\t"+user.size3rdparty['Analytics'].size.to_s+"\t"+user.size3rdparty['Social'].size.to_s+"\t"+user.size3rdparty['Content'].size.to_s+"\t"+user.size3rdparty['Beacons'].size.to_s+"\t"+user.size3rdparty['Other'].size.to_s+"\t"+avgDurPerCat.gsub(",","\t").gsub("[","").gsub("]","")+"\t"+sumSizePerCat.gsub(",","\t").gsub("[","").gsub("]","").to_s+"\t" 

		cats=['Advertising','Analytics','Social','Content','Beacons','Other']
		cats.each{|cat| 
			Utilities.printCat(fw,cat,0,trace)
		}
		cats.each{|cat| 
			Utilities.printCat(fw,cat,1,trace)
		}
		fw.puts ;
		fw.close
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

	def Utilities.calculateHost(url)
		temp=url.split("?").first.split("/").first.split(".")
		if Utilities.is_numeric?(temp[temp.size-2]) and Utilities.is_numeric?(temp[temp.size-1])
			return url
		elsif (url.include? 'co.jp' or url.include? 'co.uk' or url.include? 'co.in' or url.include? 'com.br' or url.include? 'com.au' or url.include? 'org.br' )
			return temp[temp.size-3]+"."+temp[temp.size-2]+"."+temp[temp.size-1]
		else
			return temp[temp.size-2]+"."+temp[temp.size-1]
		end
	end

	def Utilities.tokenizeHost(host)
		parts=host.split(".")
		if (host.include? 'co.jp' or host.include? 'co.uk' or host.include? 'co.in' or host.include? 'com.br' or host.include? 'com.au' or host.include? 'org.br' )
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
		puts "---> "+caller[0][/`([^']*)'/, 1]+": WARNING: "+str
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
        	system('sort -g '+file+' | uniq -c | sort -rg  > '+file+"_cnt") #calculate distribution
		end	
	end

	def Utilities.readConfigFile(configFile)
       	file = File.read(configFile)
       	options = JSON.parse(file)
		return options
	end

	def Utilities.produceConfigFile(configFile,files,tables)
		defaultOptions={"header"=>true,"printToSTDOUT"=>true, 'resultToFiles'=>
			{files[0]=>true, files[1]=>true,
			files[2]=>true, files[3]=>true},
			'tablesDB'=>{tables["publishersTable"].keys[0]=>false, tables["bcnTable"].keys[0]=>true,
			tables["impTable"].keys[0]=>false, tables["bcnTable"].keys[0]=>true,
			tables["adsTable"].keys[0]=>true, tables["userTable"].keys[0]=>true,
			tables["priceTable"].keys[0]=>true,	tables["traceTable"].keys[0]=>true,tables["csyncTable"].keys[0]=>true}}
		File.open(configFile,"w") do |f|
		  f.write(JSON.pretty_generate(defaultOptions, :indent => "\t"))
		end
		return defaultOptions
	end
end
