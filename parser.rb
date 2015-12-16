require 'optparse'
require 'ops'

ops=Operations.new

OptionParser.new { |opts|
  opts.banner = "Usage: #{File.basename($0)} -p -s -a -f -h"

  opts.on( '-s', '--separate', 'Separate fields to files. Produced files are stored in ./data/ folder') do
    ops.load()
    ops.separate
  end

  opts.on('-p', '--strip', 'Strip parameters from URLs. Output is stored in ./stripParam.out') do
    ops.load()
    ops.stripURL
  end

  opts.on('-r', '--remove', 'Remove all folders and files') do
    ops.clearAll
  end	
	
  opts.on('-f', '--find STRING', 'Search particular string in the dataset.') do |str|
    ops.load()
    ops.findStrInRows(str,true)
  end

  opts.on('-a', '--all', 'Load dataset, separate parameters, detect ads') do
    ops.load()
    ops.separate
    ops.stripURL
  end

#  opts.on('-t', '--test', 'TEST') do
#    ops.load(filename)
#    ops.test
#  end

}.parse!
