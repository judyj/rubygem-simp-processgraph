# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

describe "testing input only to process graph" do

  theGraph = ProcessList.new("testfile", nil)
  theGraph.processData("testfile", nil, "test domain")

  it "created given input file [testfile]" do
     expect(File).to exist("testfile")
  end
  it "created dot file from input name" do
     expect(File).to exist("testfile.dot")
  end

  it "created png file from input name" do
     expect(File).to exist("testfile.png")
  end
end
