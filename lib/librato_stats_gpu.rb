#!/usr/bin/ruby

realpath = File.realdirpath(__FILE__)
include_path = File.join(File.dirname(realpath), File.basename(realpath, File.extname(realpath)))

# stub module
module LibratoStats
  class GPU
  end
end

require File.join(include_path, 'gpu')
require File.join(include_path, 'version')
