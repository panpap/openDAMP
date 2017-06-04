class CSync
	def initialize(filters,trace,webVsApp,webTrace,appTrace)
		@trace=trace
		@webVsApp=webVsApp
		@filters=filters
		@webTrace=webTrace
		@appTrace=appTrace
		@params_cs=Hash.new(nil)
	end

	def checkForSync(row,cat)
		return if row['status']!=nil and (row['status']=="200" or row['status']=="204" or row['status']=="404" or row['status']=="522") # usually 303,302,307 redirect status
		curUser=row['IPport']
		urlAll=row['url'].split("?")[0..1]
		return if (urlAll.last==nil)
		@params_cs[curUser]=Hash.new(nil) if @params_cs[curUser]==nil
		curNoTLDHost=Utilities.calculateHost(urlAll.first,nil) # host without TLD
		checkCSinReffererParams(Marshal.load( Marshal.dump(row) ))
		if not checkCSinParams(urlAll,row,cat,curNoTLDHost) 
			checkCSinURI(urlAll,row,cat,curNoTLDHost)
		end
	end


private
	@@shortURLs=["//t.co/", "//bit.ly/", "//goo.gl/","//ow.ly/","//youtu.be/","tinyurl.com/","//deck.ly/","//lnk.co/","//su.pr/","//fur.ly/"]

	def	checkCSinURI(urlParts,row,cat,noTLDHost)
		curUser=row['IPport']
		found=false
        if cat==nil
            cat=@filters.getCategory(urlParts,noTLDHost,curUser)
            cat="Other" if cat==nil
        end
		return found if @@shortURLs.any? {|word| urlParts.first.downcase.include?(word)}
		parts=urlParts.first.split("/")
		for i in 1..parts.size	#skip actual domain
			parts[i]=parts[i].split("=")[1] if parts[i]!=nil and parts[i].include? "="
			if @filters.is_it_ID?(nil,parts[i],false)# and (["turn","atwola","tacoda"].any? {|word| urlParts.first.include? word})
				if @params_cs[curUser][parts[i]]==nil #first seen ID
                    @params_cs[curUser][parts[i]]=Array.new
                else    #have seen that ID before -> possible cookieSync
                    prev=@params_cs[curUser][parts[i]].last
                    if prev['host'].split(".")[0]!=noTLDHost.split(".")[0] and @filters.getRootHost(prev['host'],nil)!=@filters.getRootHost(noTLDHost,nil) 
						if row['types'].to_s!="video" and parts[i-1].include? "." 
							it_is_CM(row,prev,noTLDHost,[parts[i-1],parts[i]],"URI",urlParts,-1,cat) 
							found=true
						end
					end
				end
				@params_cs[curUser][parts[i]].push({"url"=>urlParts,"paramName"=>parts[i-1],"tmstp"=>row['tmstp']+"-REF","cat"=>cat,"status"=>row["status"],"host"=>noTLDHost,"httpRef"=>row["httpRef"], "browser" => row["browser"] , "ua" => row["ua"], "piggybacked" => "URI"})
			end
		end
		return found
	end

	def it_is_CM(row,prev,noTLDHost,paramPair,piggybacked,urlAll,ids,curCat)
		curUser=row['IPport']
#prevTimestamp|curTimestamp|hostPrev|prevCat|hostCur|curCat|paramNamePrev|userID|paramNameCur|possibleNumberOfIDs|prevStatus|curStatus|allParamsPrev|allParamsCur
		prevHost=prev['host']
		params=[curUser,prevHost,prev['cat'],noTLDHost,curCat,prev["paramName"], paramPair.last, paramPair.first,ids.to_s,prev['url'].last.split("&").to_s, urlAll.last.split("&").to_s, prev["url"].first+"?"+prev["url"].last,row["url"],prev['piggybacked'],piggybacked]


		id=Digest::SHA256.hexdigest (params.sort.join("|"))

		str=params.sort.join("|")
puts "\n----->>> "+str+" "+id if str.include? "smartadserver."

		@trace.users[curUser].csync.push(params.push(prev['status']))
		@trace.users[curUser].csync.push(params.push(row["status"]))
		@trace.users[curUser].csync.push(params.push(prev['httpRef']))
		@trace.users[curUser].csync.push(params.push(row['httpRef']))
		@trace.users[curUser].csync.push(params.push(row["dev"].to_s))
		@trace.users[curUser].csync.push(params.push(prev["browser"].to_s))
		@trace.users[curUser].csync.push(params.push(row["browser"].to_s))
		@trace.users[curUser].csync.push(params.push(prev["ua"].to_s))
		@trace.users[curUser].csync.push(params.push(row["ua"].to_s))
		@trace.users[curUser].csync.push(params.push(prev['tmstp']))
		@trace.users[curUser].csync.push(params.push(row['tmstp']))
		@trace.users[curUser].csync.push(params.push(id))
		@trace.users[curUser].csyncIDs[paramPair.last]=0 if @trace.users[curUser].csyncIDs[paramPair.last]==nil
		#@trace.users[curUser].csyncHosts[prevHost+">"+noTLDHost]=Array.new if @trace.users[curUser].csyncHosts[prevHost+">"+noTLDHost]==nil
		#@trace.users[curUser].csyncHosts[prevHost+">"+noTLDHost].push(confirmed)
		@trace.users[curUser].csyncIDs[paramPair.last]+=1
		@trace.cooksyncs+=1
		if @webVsApp
			if row['browser']!="unknown"
				@webTrace.cooksyncs+=1
			else
				@appTrace.cooksyncs+=1
			end
		end
	end

	def checkCSinParams(urlParts,row,cat,noTLDHost)
		curUser=row['IPport']
		exclude=["cb","token", "nocache"]
#		confirmed=0
		ids=0
		found=false
		fields=urlParts.last.split('&')
		return found if fields.size>8 # usually there are very few params_cs (only sessionids)
		for field in fields do
            paramPair=field.split("=")
            if @filters.is_it_ID?(paramPair.first,paramPair.last,true)
                ids+=1
#confirmed+=1 if @params_cs[curUser].keys.any?{ |word| paramPair.last.downcase.eql?(word)} 
                if cat==nil
                    cat=@filters.getCategory(urlParts,noTLDHost,curUser)
                    cat="Other" if cat==nil
                end
                if @params_cs[curUser][paramPair.last]==nil #first seen ID
                    @params_cs[curUser][paramPair.last]=Array.new
                else    #have seen that ID before -> possible cookieSync
                    prev=@params_cs[curUser][paramPair.last].last
                    if prev['host'].split(".")[0]!=noTLDHost.split(".")[0] and @filters.getRootHost(prev['host'],nil)!=@filters.getRootHost(noTLDHost,nil) 
						if not urlParts.last.include? prev['host'] 								#CASE OF PIGGYBACKED URLS
							if row['types'].to_s!="video"
						#puts paramPair.last.size
                    			it_is_CM(row,prev,noTLDHost,paramPair,"PARAM",urlParts,ids,cat)
								found=true
							end
						end
                    end
                end
				@params_cs[curUser][paramPair.last].push({"url"=>urlParts,"paramName"=>paramPair.first,"tmstp"=>row['tmstp'],"cat"=>cat,"status"=>row["status"],"host"=>noTLDHost,"httpRef"=>row["httpRef"], "browser" => row["browser"] , "ua" => row["ua"], "piggybacked" => "PARAM"})
            end
        end
		return found
	end

	def checkCSinReffererParams(curRow)	
		found=false
		return found if curRow['httpRef']==-1 or curRow['httpRef']=="-"
		curUser=curRow['IPport']
		exclude=["cb","token", "nocache"]
		ids=0
		curRow['url']=curRow['httpRef'].gsub("http://","")
		urlParts=curRow['url'].split("?")[0..1]
		return found if (urlParts.last==nil)
		curHost=Utilities.calculateHost(urlParts.first,nil)
		curRow['host']=curHost
		curRow['httpRef']="REFANALYSIS" 
		cat=@filters.getCategory(urlParts,curHost,curUser)
		cat="Other" if cat==nil
		fields=urlParts.last.split('&')
		return found if fields.size>12 # usually there are very few params_cs (only sessionids)
		for field in fields do
            paramPair=field.split("=")
            if @filters.is_it_ID?(paramPair.first,paramPair.last,true)
                ids+=1
                if @params_cs[curUser][paramPair.last]==nil #first seen ID
                    @params_cs[curUser][paramPair.last]=Array.new
                else    #have seen that ID before -> possible cookieSync
                    prev=@params_cs[curUser][paramPair.last].last
                    if prev['host'].split(".")[0]!=curHost.split(".")[0] and @filters.getRootHost(prev['host'],nil)!=@filters.getRootHost(curHost,nil) 
						if not urlParts.last.include? prev['host'] 								#CASE OF PIGGYBACKED URLS
							if curRow['types'].to_s!="video"
						#puts paramPair.last.size
                    			it_is_CM(curRow,prev,curHost,paramPair,"REFF",urlParts,ids,cat)
								found=true
							end
						end
                    end
                end
				@params_cs[curUser][paramPair.last].push({"url"=>urlParts,"paramName"=>paramPair.first,"tmstp"=>curRow['tmstp'],"cat"=>cat,"status"=>curRow["status"],"host"=>curHost,"httpRef"=>curRow["httpRef"], "browser" => curRow["browser"] , "ua" => curRow["ua"], "piggybacked" => "REFF"})
            end
        end
		return found
	end

end
