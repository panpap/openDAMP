module Utilities

	def Utilities.loadOptions(configFile)
		if File.exists? (configFile)
			return Utilities.readConfigFile(configFile)
		else	# DEFAULT
			return Utilities.produceConfigFile(configFile)
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

	def Utilities.tokenizeHost(host)
		parts=host.split(".")
		if (host.include? 'co.jp' or host.include? 'co.uk' or host.include? 'co.in')
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
		abort "---> "+caller[0][/`([^']*)'/, 1]+":ERROR: "+str
	end

	def Utilities.printRowToDB(row,db,table,extra)
		if db!=nil
			id=""
			if (h['httpRef']!=nil)
				id=Digest::SHA256.hexdigest (id=Digest::SHA256.hexdigest (row.values.join("|"))+"|"+h['httpRef'])
			else
				id=Digest::SHA256.hexdigest (id=Digest::SHA256.hexdigest (row.values.join("|")))
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
		options=Hash.new
		puts "TODO"
		File.foreach(configFile) {|line|
			puts line
		}
		return {'file'=>1,'detail'=>1, 'excludeCol'=>1}#options
	end

	def Utilities.produceConfigFile(configFile)
		puts "TODO"
		options={'file'=>1,'detail'=>1, 'excludeCol'=>1}
		fw=File.new(configFile,"w")
		fw.puts options
		fw.close
		return options
	end
end
