load 'defines.rb'
load 'ops.rb'
require 'optparse'

def	 folderAsInput(arg)
	if arg==nil
		Utilities.error("Wrong arguments given. Please give folder to load...")
	end
	path=arg.split("results_")[1]
	if path==nil
		Utilities.error("Wrong arguments given. Please give folder to load...")
	end
	lastChar="";trace="",folder=""
	if path.include? "/"
		trace=path.split("/")[0]
		lastChar=path[path.size-2]
		folder=arg
	else
		trace=path
		lastChar=path[path.size-1]
		folder=arg+"/"
	end
	s=trace
	if Utilities.is_numeric?(lastChar)
		parts=trace.split("_")
		s=parts[1].gsub(lastChar,"")
		s=parts[0]+"_"+s
	end
	return Operations.new(s),folder
end

start = Time.now

OptionParser.new { |opts|
  opts.banner = "Usage: #{File.basename($0)} [-p -s -c -g -d -a -h -o] [-f <SEARCH_STRING>] [-t <TIME_WINDOW>] [FILENAME]"

	opts.on( '-s', '--separate', 'Separate fields to files. Produced files are stored in ./data/ folder') do
		ops=Operations.new(ARGV[0])
		puts "> Separating HTTP fields..."
		ops.dispatcher(1,nil)
	end

	opts.on('-o', '--analysis', 'Parse and analyze dataset.') do
		ops=Operations.new(ARGV[0])
		puts "> Parsing and analyzing dataset..."
		ops.dispatcher(2,nil)
	end	

	opts.on('-f', '--find STRING', 'Search particular string in the dataset.') do |str|
		ops=Operations.new(ARGV[0])
		puts "> Searching String..."
		ops.dispatcher(3,str)
	end

	opts.on('-a', '--all', 'Load dataset, separate parameters, detect ads') do
		ops=Operations.new(ARGV[0])
		ops.dispatcher(0,nil)
	end

	opts.on('-p', '--plot', 'Plot CDFs using Gnuplot') do
		ops,folder=folderAsInput(ARGV[0])
		ops.plot(folder)
	end

	opts.on('-g', '--config', 'Config') do
		puts "> Config file check"
		ops=Operations.new(ARGV[0])
	end

	opts.on('-c', '--cookieSync', 'Cookie synchronization detection') do
		puts "> Cookie synchronization detection"
		ops=Operations.new(ARGV[0])
		ops.dispatcher(4,nil)
	end

	opts.on('-t', '--timelines MILLISECONDS', 'Make user Timelines per N milliseconds') do |sec|
		ops,folder=folderAsInput(ARGV[0])
		ops.makeTimelines(sec,folder)
	end

	opts.on('-d', '--dublicates', 'Count possible duplicate rows in dataset.') do		
		ops=Operations.new(ARGV[0])
		puts "Counting possible duplicates..."
		ops.countDuplicates
	end
}.parse!
finish = Time.now
puts "Total Elapsed time "+(finish - start).to_s+" seconds"

