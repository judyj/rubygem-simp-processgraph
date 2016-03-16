# Add a testclass
# run the process
# make sure the files are created
#
require 'simp-processgraph'
require_relative 'spec_helper'

describe "testing process graph with no parms" do

  theGraph = ProcessList.new
  theGraph.processData(nil, nil, "my site")

  it "created input file based on default [process_list]" do
     expect(File).to exist("process_list")
  end

  it "created dot file based on default" do
     expect(File).to exist("process_list.dot")
  end

  it "created png file based on default" do
     expect(File).to exist("process_list.png")
  end

end
