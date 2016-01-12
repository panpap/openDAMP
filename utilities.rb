module Utilities
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

	def Utilities.separateTimelineEvents(row,writeTo)
		fp=File.new(writeTo,'a')
		fp.puts(row['IPport']+"\t"+
		    row['uIP'].to_s+"\t"+
		    row['url']+"\t"+
		    row['ua']+"\t"+
		    row['host']+"\t"+
		    row['tmstp']+"\t"+
		    row['status']+"\t"+
		    row['length']+"\t"+
		    row['dataSz']+"\t"+
		    row['dur'])
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
		result={'sum'=>-1,'avg'=>-1,'median'=>-1,'max'=>-1,'min'=>-1}
		if arr!=nil or arr.length>0
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

	def Utilities.results_toString(trace,printVertical)
		numericPrices=Array.new
		prices=trace.detectedPrices
        for p in prices do
            if Utilities.is_float?(p)
                numericPrices.push(p.to_f)
            end
        end
		totalNumofRows=trace.rows.size
		pricesStats=Utilities.makeStats(numericPrices)
		paramsStats,sizeStats=trace.analyzeTotalAds
		#PRINTING RESULTS
		if printVertical
			s="> Printing Results...\nTRACE STATS\n------------\n"+"Total users in trace: "+trace.users.size.to_s+"\n"+"Traffic from  mobile devices: "+
			trace.mobDev.to_s+"/"+totalNumofRows.to_s+"\n"+"Traffic originated from Browser: "+trace.fromBrowser.size.to_s+"\n Browser-prices: "+trace.browserPrices.to_s+"\n"+"3rd Party content detected:"+"\n"+"Advertising => "+trace.party3rd['Advertising'].to_s+
			" Analytics => "+trace.party3rd['Analytics'].to_s+" Social => "+trace.party3rd['Social'].to_s+" Content => "+trace.party3rd['Content'].to_s+
			" Beacons => "+trace.party3rd['totalBeacons'].to_s+" Other => "+trace.party3rd['Other'].to_s+"\n"+
			"\nSize of the unnecessary 3rd Party content (i.e. Adverising+Analytics+Social)\nTotal: "+sizeStats['sum'].to_s+" Bytes - Average: "+
			sizeStats['avg'].to_s+" Bytes"+"\n"+"Total Number of rows = "+(trace.party3rd['Advertising']+trace.party3rd['Analytics']+trace.party3rd['Social']+
			trace.party3rd['totalBeacons']+trace.party3rd['Content']+trace.party3rd['Other']-trace.totalAdBeacons).to_s+"\n"+"Total Ads-related requests found: "+
			trace.party3rd['Advertising'].to_s+"/"+totalNumofRows.to_s+"\n"+"Ad-related traffic using mobile devices: "+trace.numOfMobileAds.to_s+"/"+
			trace.party3rd['Advertising'].to_s+"\n"+"Number of parameters:\nmax => "+paramsStats['max'].to_s+" min=>"+paramsStats['min'].to_s+" avg=>"+
			paramsStats['avg'].to_s+"\n"+"Price tags found: "+prices.length.to_s+"\n"+numericPrices.size.to_s+"/"+prices.size.to_s+
			" are actually numeric values"+"\n"+"Average price "+pricesStats['avg'].to_s+"\n"+"Beacons found: "+trace.party3rd['totalBeacons'].to_s+
			"\nAds-related beacons: "+trace.totalAdBeacons.to_s+"/"+trace.party3rd['totalBeacons'].to_s+"\n"+"Impressions detected "+trace.totalImps.to_s+"\n"+
	#        puts "Average latency "+avgL.to_s
			"PER USER STATS"+"\n"+"TODO"
			return s
		else
			header="Total users in trace;Traffic from mobile devices;Traffic originated from Browser;Browser-prices;"+
			"3rd Party content detected: [Advertising,Analytics,Social,Content,Beacons,Other];"+
			"3rd Party content size: [Total,Average];Total Number of rows;Total Ads-related requests found;Ad-related traffic using mobile devices;"+
			"Number of parameters:[max,min,avg];Price tags found;numeric values;Average price;Beacons found;Ads-related beacons;Impressions detected;Publishers;\n"
			s=trace.users.size.to_s+";"+
			trace.mobDev.to_s+"/"+totalNumofRows.to_s+";"+trace.fromBrowser.size.to_s+";"+trace.browserPrices.to_s+";["+trace.party3rd['Advertising'].to_s+
			","+trace.party3rd['Analytics'].to_s+","+trace.party3rd['Social'].to_s+","+trace.party3rd['Content'].to_s+
			","+trace.party3rd['totalBeacons'].to_s+","+trace.party3rd['Other'].to_s+"];["+sizeStats['sum'].to_s+","+
			sizeStats['avg'].to_s+"];"+(trace.party3rd['Advertising']+trace.party3rd['Analytics']+trace.party3rd['Social']+
			trace.party3rd['totalBeacons']+trace.party3rd['Content']+trace.party3rd['Other']-trace.totalAdBeacons).to_s+";"+
			trace.party3rd['Advertising'].to_s+"/"+totalNumofRows.to_s+";"+trace.numOfMobileAds.to_s+"/"+
			trace.party3rd['Advertising'].to_s+";["+paramsStats['max'].to_s+","+paramsStats['min'].to_s+","+
			paramsStats['avg'].to_s+"];"+prices.length.to_s+";"+numericPrices.size.to_s+"/"+prices.size.to_s+
			";"+pricesStats['avg'].to_s+";"+trace.party3rd['totalBeacons'].to_s+
			";"+trace.totalAdBeacons.to_s+"/"+trace.party3rd['totalBeacons'].to_s+";"+trace.totalImps.to_s
			if trace.publishers.size>0 
				str="["
				trace.publishers.each{ |pubs| str=str+" | "+pubs}
				return header+s+str+"]\n"
			else
				return header+s+"\n"
			end
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
		if File.exists?(file)
        	system('sort -n '+file+' | uniq > '+file+"_uniq")
        	system('sort -n '+file+' | uniq -c | sort -n  |tac > '+file+"_cnt") #calculate distribution
		end	
	end
end
