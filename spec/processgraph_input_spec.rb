# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'
require 'fileutils'

describe "testing input only to process graph" do

# create a temp dir for output
  site_name = "test_domain"
  outdir = File.join('processgraph_output',site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)

  Dir.chdir(outdir) do
    the_graph = ProcessList.new("testfile", nil, false)
    the_graph.process_data(site_name, 0)
  end

  it "created given input file [testfile]" do
     expect(File).to exist("#{outdir}/testfile.raw")
  end
  it "created dot file from input name" do
     expect(File).to exist("#{outdir}/testfile.dot")
  end

  it "created png file from input name" do
     expect(File).to exist("#{outdir}/testfile.png")
  end
end
