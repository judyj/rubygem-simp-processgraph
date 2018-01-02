# Add a testclass
# run the process
# make sure the files are created
#
require 'fileutils'
require 'simp-processgraph'
require_relative 'spec_helper'

describe "testing process graph with two inputs" do
# create a temp dir for output
  site_name = "test_domain"
  outdir = File.join('processgraph_output',site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)

  Dir.chdir(outdir) do
    the_graph = ProcessList.new("filein", "fileout", false)
    the_graph.process_data(site_name, 0)
  end

  it "created input file [filein] given in and out names" do
     expect(File).to exist("#{outdir}/filein.raw")
  end

  it "created dot file [fileout] given in and out names" do
     expect(File).to exist("#{outdir}/fileout.dot")
  end

  it "created png file given in and out names" do
     expect(File).to exist("#{outdir}/fileout.png")
  end

end

