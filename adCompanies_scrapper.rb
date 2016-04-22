load 'database.rb'
load 'utilities.rb'

types=["demand-side-platform-dsp"#,"data-management-platform-dmp","native-advertising","ad-network","attribution","display-advertising","video-advertising","search-advertising","social-advertising","cross-channel-advertising","advertiser-campaign-management","publisher-ad-management","mobile-advertising","supply-side-platform-ss","other-digital-advertising"
]
comp=Hash.new(nil)
types.each{|type| finished=false
	page=1
	while(finished==false)
		print "\nChecking "+type
		lines=`wget -qO- "https://www.g2crowd.com/categories/#{type}/products?&page=#{page}"`.split("data-lead-modal-url=\"/products/")
		if lines.size<2
			puts "\n...finished..."
			finished=true
		else
			lines.each{|ln| 
				companyName=ln.split("/").first
				moreLines=`wget -qO- "https://www.g2crowd.com/products/#{companyName}/details"`.split("\n")
				url=nil
				moreLines.each{|ln2| 					
					if ln2.include? "Product Website"
						url=ln2.split("Product Website").last.split("</a>").first.split("href=").last.split(">").first.gsub("</a","")
						break
					end
				}
				if comp[companyName]==nil
					comp[companyName]={"url"=>url.to_s.downcase, "cats"=>[]}
				end
				comp[companyName]["cats"].push(type)
			}
			puts "..."+page.to_s+"..."
			page+=1
		end
	end
}

puts "Dumping to DB..."
db = Database.new(nil,"companies.db")
tableName="adCompanies"
db.create(tableName,'name VARCHAR, url VARCHAR PRIMARY KEY,  categories VARCHAR')
comp.each{|name, value| 
	if not name.include?"html>"
		params=[name,value["url"],value["cats"].to_s]
		db.insert(tableName, params)
	end
}
