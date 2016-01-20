require 'optparse'
load 'utilities.rb'
load 'ops.rb'

def	 folderAsInput(arg)	
	path=arg.split("results_")[1]
	if path==nil
		abort ("Error: Wrong arguments given. Please give folder to load...")
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
	return Operations.new(s,false),folder
end

start = Time.now


OptionParser.new { |opts|
  opts.banner = "Usage: #{File.basename($0)} [-p -s -a -h] [-f <Search_string>] [-t <time_window>] [filename (optional)]"

  opts.on( '-s', '--separate', 'Separate fields to files. Produced files are stored in ./data/ folder') do
	ops=Operations.new(ARGV[0],true)
    ops.loadFile()
    ops.separate
  end

  opts.on('-p', '--parse', 'Parse and analyze dataset.') do
	ops=Operations.new(ARGV[0],true)
    ops.loadFile()
    ops.analysis
  end	
	
  opts.on('-f', '--find STRING', 'Search particular string in the dataset.') do |str|
	ops=Operations.new(ARGV[0],false)
    ops.loadFile()
    ops.findStrInRows(str,true)
  end

  opts.on('-a', '--all', 'Load dataset, separate parameters, detect ads') do
	ops=Operations.new(ARGV[0],true)
    ops.loadFile()
    ops.separate
    ops.stripURL
  end

  opts.on('-l', '--plot', 'Plot CDFs using Gnuplot') do
	ops,folder=folderAsInput(ARGV[0])
    ops.plot(folder)
  end

  opts.on('-t', '--timelines MILLISECONDS', 'Make user Timelines per N milliseconds') do |sec|
	ops,folder=folderAsInput(ARGV[0])
	ops.makeTimelines(sec,folder)
  end

}.parse!
finish = Time.now
puts "Total Elapsed time "+(finish - start).to_s+" seconds"
