# Add a testclass
# run the process
# make sure the files are created
#
require 'fileutils'
require 'simp-processgraph'
require_relative 'spec_helper'

describe 'testing process graph with two inputs' do
  # create a temp dir for output
  site_name = 'test_domain'
  outdir = File.join('processgraph_output', site_name)
  # create out directory if does not exist
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)
  # run the process fromthat directory with the 3 parameters
  Dir.chdir(outdir) do
    the_graph = ProcessList.new('filein', 'fileout', false)
    the_graph.process_data(site_name, 0)
  end
  # check for raw file
  it 'created input file [filein] given in and out names' do
    expect(File).to exist("#{outdir}/filein.raw")
  end
  # check for dot file
  it 'created dot file [fileout] given in and out names' do
    expect(File).to exist("#{outdir}/fileout.dot")
  end
  # check for png file
  it 'created png file given in and out names' do
    expect(File).to exist("#{outdir}/fileout.png")
  end
end
