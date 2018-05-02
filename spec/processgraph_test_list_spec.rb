# Add a testclass
# run the process
# make sure the debug list capability works
#
require 'simp-processgraph'
require_relative 'spec_helper'
require 'fileutils'

site_name = 'test_domain'
# con_type = 0
home_dir = File.expand_path('~')
test_dir = home_dir + '/ssfiles'
this_dir = File.expand_path('.')
sample_file = 'spec/fixtures/sample.ss'
unless File.directory?(test_dir)
  stderr.puts "created directory, copied in #{sample_file}"
  FileUtils.mkdir(test_dir)
end
FileUtils.cp(sample_file, test_dir)

describe 'testing output debug info' do
  # create a temp dir for output
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)

  Dir.chdir(outdir) do
    the_graph = ProcessList.new(test_dir, 'testdir', false)
    the_graph.process_data(site_name, 0)
    innewfiles = `pwd`.strip
    # call print_sites (debug tool) just to make sure we have code coverage
    the_graph.print_sites("#{this_dir}/#{outdir}/testdir.debug")
  end
  # create dot file
  it 'created dot file from input directory name [testdir]' do
    expect(File).to exist("#{outdir}/testdir.dot")
  end
  # created png file
  it 'created png file from input directory name [testdir]' do
    expect(File).to exist("#{outdir}/testdir.png")
  end
end
