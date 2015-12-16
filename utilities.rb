class Utilities
	def median(array)
  		sorted = array.sort
  		len = sorted.length
		return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
	end

        def is_float?(object)
                if (not object.include? "." or object.downcase.include? "e") #out of range check
                        return false
                else
                        return is_numeric?(object)
                end
        end

        def openFiles 
                fi=File.new(@@adsDir+@@impB,'w')
                fa=File.new(@@adsDir+@@adfile,'w')
                fl=File.new(@@leftovers,'w')
                fp=File.new(@@adsDir+@@prices,'w')
                fn=File.new(@@adsDir+@@paramsNum,'w')
                fd1=File.new(@@adsDir+@@devices,'w')
                fb=File.new(@@adsDir+@@bcnFile,'w')
                fm=File.new("mopub.out",'w')
                fz=File.new(@@adsDir+@@size3rdFile,'w')
                fd2=File.new(@@adsDir+@@adDevices,'w')
	        return fi,fa,fl,fp,fn,fd1,fb,fm,fz,fd2
        end

        def is_numeric?(object)
               	if object==nil
                        return false
                end
                true if Float(object) rescue false
        end

       	def stripper(str)
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

       	def printStrippedURL(url,fw)
		params=stripper(url[1])
                fw.puts "\n"+url[0]+" "
                if params!=""
                        fw.puts params
                else
                    	fw.puts "----"
               	end
        end

        def makeDistrib_LaPr(adsDir)            # Calculate Latency and Price distribution
                countInstances("./","latency.out")        #latency
                system("awk \'{print $2\" \"$1}\' "+adsDir+"prices | sort -n | uniq -c | sort -n | tac > "+adsDir+"prices_cnt")
                system("awk \'{print $2\" \"$1}\' "+adsDir+"prices | sort -n | uniq > "+adsDir+"prices_uniq")
        end

	def printRow(row,fw)
                for key in row.keys
                        fw.puts key+" => "+row[key]
			if key=="url"
				printStrippedURL(row[key].split('?'),fw)
			end
                end
                fw.puts "------------------------------------------------"
        end

	def countInstances(dir,att)
	        system('sort -n '+dir+att+' | uniq > '+dir+att+"_uniq")
                system('sort -n '+dir+att+' | uniq -c | sort -n  |tac > '+dir+ att+"_cnt") #calculate distribution
	end	
end
