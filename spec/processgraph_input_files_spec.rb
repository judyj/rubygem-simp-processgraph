# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'
require 'fileutils'

describe 'testing input raw and ss to processgraph' do
  # create a temp dir for output
  site_name = 'test_domain'
  rawfile = 'rawfile.raw'
  ssfile = 'ssfile.ss'
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)

  # read sample raw file 
  sample_file = "#{Dir.pwd}/spec/fixtures/#{rawfile}"
  puts sample_file
  Dir.chdir(outdir) do
    the_graph = ProcessList.new(sample_file, nil, true)
    the_graph.process_data(site_name, 0)
  end
  # check for dotfile
  it 'created dot file from raw input name' do
    expect(File).to exist("#{outdir}/#{rawfile}.dot")
  end
  # and for png
  it 'created png file from raw input name' do
    expect(File).to exist("#{outdir}/#{rawfile}.png")
  end

  # read sample ss file 
  sample_file = "#{Dir.pwd}/spec/fixtures/#{ssfile}"
  puts sample_file
  Dir.chdir(outdir) do
    the_graph = ProcessList.new(sample_file, nil, false)
    the_graph.process_data(site_name, 0)
  end
  # check for dotfile
  it 'created dot file from ss input name' do
    expect(File).to exist("#{outdir}/#{ssfile}.dot")
  end
  # and for png
  it 'created png file from ss input name' do
    expect(File).to exist("#{outdir}/#{ssfile}.png")
  end



end

