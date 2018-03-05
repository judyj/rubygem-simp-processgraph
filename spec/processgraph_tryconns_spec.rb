# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'
require 'fileutils'

# Connection Type (T = Port = 0, R = Process = 1, I = IP = 2)
site_name = 'test_domain'
# test port function
describe 'testing default to port' do
  con_type = 0
  file_name = 'port'
  # create a temp dir for output
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)
  # create graph of ports
  Dir.chdir(outdir) do
    the_graph = ProcessList.new(nil, file_name, false)
    the_graph.process_data(site_name, con_type)
  end
  # make sure you get a dotfile
  it 'created dot file from file name' do
    expect(File).to exist("#{outdir}/#{file_name}.dot")
  end
  # and png file
  it 'created png file from port filename' do
    expect(File).to exist("#{outdir}/#{file_name}.png")
  end
end
# change to do process graph
describe 'testing default to process' do
  con_type = 1
  file_name = 'process'
  # create a temp dir for output
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)
  # create the graph
  Dir.chdir(outdir) do
    the_graph = ProcessList.new(nil, file_name)
    the_graph.process_data(site_name, con_type)
  end
  # ensure a dot file
  it 'created dot file from port file name' do
    expect(File).to exist("#{outdir}/#{file_name}.dot")
  end
  # ensure a ping file
  it 'created png file from port filename' do
    expect(File).to exist("#{outdir}/#{file_name}.png")
  end
end
# change to do ip graph
describe 'testing default to ip' do
  con_type = 2
  file_name = 'ip'
  # create a temp dir for output
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)
  # create the graph
  Dir.chdir(outdir) do
    the_graph = ProcessList.new(nil, file_name)
    the_graph.process_data(site_name, con_type)
  end
  # .. and dot file
  it 'created dot file from file name' do
    expect(File).to exist("#{outdir}/#{file_name}.dot")
  end
  # and png file
  it 'created png file from port filename' do
    expect(File).to exist("#{outdir}/#{file_name}.png")
  end
end
