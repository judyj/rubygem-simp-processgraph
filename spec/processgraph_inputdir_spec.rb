# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'
require 'fileutils'

site_name = 'test_domain'
con_type = 0
home_dir = File.expand_path('~')
test_dir = home_dir + '/ssfiles'
sample_file = 'spec/fixtures/sample.ss'
unless File.directory?(test_dir)
  puts "created directory, copied in #{sample_file}"
  FileUtils.mkdir(test_dir)
end
FileUtils.cp(sample_file, test_dir)

describe 'testing input directory to process graph' do
  # create a temp dir for output
  outdir = File.join('processgraph_output', site_name)
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)

  Dir.chdir(outdir) do
    the_graph = ProcessList.new(test_dir, 'testdir', false)
    the_graph.process_data(site_name, con_type)
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
