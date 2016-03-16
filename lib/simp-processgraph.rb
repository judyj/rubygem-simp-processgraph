#!/usr/bin/env ruby

######################################
# simp-processgraph
# This code allows you to plot the communications between your host and others.
#
# It uses the `ss` (socket statistics) command with the `-npatuw` options
# -n, --numeric    Do now try to resolve service names.
# -a, --all    Display all sockets.
# -p, --processes    Show process using socket.
# -t, --tcp    Display only TCP sockets.
# -u, --udp    Display only UDP sockets.
# -w, --raw    Display only RAW sockets.
#
# In order to run, you must set up your environment as described in https://simp-project.atlassian.net/wiki/display/SD/Setting+up+your+build+environment
# (until you install bundler)
# then
# `$bundle`
#
# In order to create the .png files, you must have graphviz installed
# sudo yum install graphviz
# ...and the ruby add-on to graphviz
#
# sudo yum install graphviz-ruby
#
# ...and to ensure you can see the Ruby libraries, type (and/or add to your .bashrc) :
# export RUBYLIB=/usr/lib64/graphviz/ruby
#
###########################################
require 'optparse'
require 'gv'
require 'socket'

class ProcessList
  attr_accessor :infile, :outfile
  def initialize(infile = nil,outfile = nil)
    @infile = infile
    @outfile = outfile
    @mySiteList = []
  end

# Process array from file
  def processData(infile, outfile, sitename)
    @inputfile = infile
    @outputfile = outfile
    @sitename = sitename

  # get the list of processes to a file
    infile = 'process_list'
    @filetype = 'none'

  # check to see if we input a file
    if @inputfile == nil
#     if file with generic name exists, back it up just in case
      if File.file?infile
        File.rename(infile, "#{infile}.bak")
      end
      @filetype = 'file'
      @inputfile = infile
    end
    if File.directory?@inputfile then
      @filetype = 'dir'
    elsif ( (File.file?@inputfile) && (File.extname(@inputfile) == ".ss") )
      @filetype = 'file'
    else
     infile = @inputfile
     @filetype = 'none'
    end

# output file
    if @outputfile == nil then
      @outputfile = @inputfile
    end

    theStart = self

#   read from file
    dataRead = FileInput(@inputfile, @outputfile, @filetype, @sitename)

#   set up objects based on the record you just read
    dataRead.each do |record|
      newSite = theStart.addSite(record["sitename"])
      newHost = newSite.addHost(record["hostname"])
      newIP = newHost.addIP(record["localIP"])
      newProc = newIP.addProc(record["procname"])
      newPort = newProc.addPort(record["localPort"])

#     destinations
#      destSite = theStart.addSite(record["sitename"])
      if ( (record["peerIP"]!= "*") && (record["peerPort"]!= "*")) then
        destSite = theStart.addSite("")
        destHost = destSite.addHost("")
        destIP = destHost.addIP(record["peerIP"])
        destProc = destIP.addProc(record[""])
        destPort = destProc.addPort(record["peerPort"])
        newPort.addConnection(destPort)
      end
    end

#   graph (boxes)
    theStart.graphProcesses(@outputfile)
#   graph (connections)
    theStart.graphConnections(@outputfile)

  end #processData

  def addSite(newSite)
    found = false
    if (@mySiteList.size > 0) then
      @mySiteList.each do |sitenm|
        thisSite = sitenm.getSiteName
        if thisSite == newSite then
          found = true
          return sitenm
        end # match
      end #each site
    end # more than one site

    if (!found) then
      addSite = SiteName.new(newSite)
      @mySiteList << addSite
      return addSite
    end
  end
 
  def printSites()
    @mySiteList.each do |sitenm|
      puts "site name is #{sitenm.getSiteName}"
      sitenm.printHosts
    end # site
  end #printSites

  def graphProcesses(outfile)
    $outputfile = outfile
#   init graph
    $gv = Gv.digraph("ProcessGraph")
    # rank TB makes the graph go from top to bottom - works better right now with the CentOS version
    # rank LR draws left to right which is easier to read
    Gv.layout($gv, 'dot')
    Gv.setv($gv, 'rankdir', 'LR')
    $upno = 0
    $sitecount = 0
    $hostcount = 0
    $ipcount = 0
    $proccount = 0
    $portcount = 0
#   progress through the sites
    @mySiteList.each do |sitenm|
      $sitecount += 1
      sg = Gv.graph($gv, "cluster#{$upno}")
      Gv.setv(sg, 'color', 'black')
      Gv.setv(sg, 'label', "#{sitenm.getSiteName}")
      Gv.setv(sg, 'shape', 'box')
      $upno += 1
#     the hosts
      hostList = sitenm.getHostList
      hostList.each do |host|
        $hostcount += 1
        sgb = Gv.graph(sg, "cluster#{$upno}")
        Gv.setv(sgb, 'color', 'red')
        Gv.setv(sgb, 'label', "#{host.getHostName}")
        Gv.setv(sgb, 'shape', 'box')
        $upno +=1
        ipList = host.getIPList
        ipList.each do |myIP|
          $ipcount += 1
          sgc = Gv.graph(sgb, "cluster#{$upno}")
          Gv.setv(sgc, 'color', 'blue')
          Gv.setv(sgc, 'label', "#{myIP.getIP}")
          Gv.setv(sgc, 'shape', 'box')
          $upno +=1
          procs = myIP.getProcs
          procs.each do |myproc|
            $proccount += 1
            sgd = Gv.graph(sgc, "cluster#{$upno}")
            Gv.setv(sgd, 'color', 'green')
            Gv.setv(sgd, 'label', "#{myproc.getProc}")
            Gv.setv(sgd, 'shape', 'box')
            $upno +=1
            portList = myproc.getPorts
            portList.each do |portno|
              $portcount += 1
              sge = Gv.graph(sgd, "cluster#{$upno}")
              Gv.setv(sge, 'color', 'black')
              Gv.setv(sge, 'label', "#{portno.getPort}")
              Gv.setv(sge, 'shape', 'box')
              ng = Gv.node(sge,"k#{$portcount}")
              Gv.setv(ng, 'label', "#{portno.getPort}")
              Gv.setv(ng, 'style', 'filled')
              Gv.setv(ng, 'shape', 'point')
              portno.setGraphNode("k#{$portcount}")
              $upno +=1
            end #ports
          end #procs
        end #ipList
      end #hostList
    end # site
  end #graphProcesses

  def graphConnections (outfile)
    $colors = Array['yellow','green','orange','violet', 'turquoise', 'gray','brown']
    count = 0
    $outputfile = outfile
#   progress through the sites
    @mySiteList.each do |sitenm|
      hostList = sitenm.getHostList
      hostList.each do |host|
        ipList = host.getIPList
        ipList.each do |myIP|
          procs = myIP.getProcs
          procs.each do |myproc|
            portList = myproc.getPorts
            portList.each do |portnum|
#             once more to get connections
              myConns = portnum.getConnections
              myConns.each do |conn|
                startNode = portnum.getGraphNode
                endNode = conn.getGraphNode
                if (endNode != nil && startNode != nil) then
                  count += 1
                  colorcode =  count.modulo($colors.size)
                  eg = Gv.edge($gv, startNode, endNode)
#                 connect the dots
                  Gv.setv(eg, 'color', $colors[colorcode])
                end  # not nil
              end #connections
            end #ports
          end #procs
        end #ipList
      end #hostList
    end # site
  success = Gv.write($gv, "#{$outputfile}.dot")
# for now, create the dot this way, see if we can find correction
  system "dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"
  puts "done -- dot -Tpng #{$outputfile}.dot -o #{$outputfile}.png"
  end #graphConnections
end #ProcessList

### Site
class SiteName
  attr_accessor :mySiteName

  def initialize(mySiteName)
    @mySiteName = mySiteName
    @myHostList = []
  end #initialize

  def addHost(newHost)
    found = false
    if (@myHostList.size > 0) then
      @myHostList.each do |hostnm|
        if newHost == hostnm.getHostName then
          found = true
          return hostnm
        end # match
      end #each site
    end # more than one

    if (!found) then
      thisHost = HostName.new(newHost)
      @myHostList << thisHost
      return thisHost
    end
  end

  def getSiteName
     return @mySiteName
  end

  def getHostList
    return @myHostList
  end

  def printHosts
    @myHostList.each do |hostnm|
      puts "hostname is #{hostnm}"
      hostnm.printIPs
    end # site
  end #printHosts

end #SiteName

### Host
class HostName
  attr_accessor :myHostName

  def initialize(myHostName)
    @myHostName = myHostName
    @myIPList = []
  end #initialize

  def addIP(myIP)
    found = false
    if (@myIPList.size > 0) then
      @myIPList.each do |ipnm|
        thisIP = ipnm.getIP
        if (thisIP == myIP) then
          found = true
          return ipnm
        end # match
      end #each site
    end # more than one

    if (!found) then
      newIP = IPAddr.new(myIP)
      @myIPList << newIP
      return newIP
    end # found
  end # addIP

  def getHostName
    return @myHostName
  end

  def getIPList
    return @myIPList
  end

  def printIPs
    @myIPList.each do |ipnm|
      puts "ip is #{ipnm.getIP}"
      ipnm.printProcs
    end # IP
  end #printIPs

end #HostName

### IP
class IPAddr
  attr_accessor :myIP

  def initialize(myIP)
    @myIP = myIP
    @myProcList = []
  end #initialize

  def getIP
    return @myIP
  end

  def getProcs
    return @myProcList
  end

  def addProc(myProc)
    found = false
    if (@myProcList.size > 0) then
      @myProcList.each do |proc|
        thisProc = proc.getProc
        if (thisProc == myProc) then
          found = true
          return proc
        end # match
      end #each site
    end # more than one

    if (!found) then
      newPL = ProcessName.new(myProc)
      @myProcList << newPL
      return newPL
    end # found
  end # addProc

  def printProcs
    @myProcList.each do |procnm|
      puts "proc is #{procnm.getProc}"
      procnm.printPorts
    end # Proc
  end #printProcs

end #IPAddr

### Process
class ProcessName
  attr_accessor :procname

  def initialize(procname)
    @procname = procname
    @myPortList = []
  end #initialize

  def getProc
    return(@procname)
  end

  def getPorts
    return(@myPortList)
  end

  def addPort(myPort)
    found = false
    if (@myPortList.size > 0) then
      @myPortList.each do |port|
        thisPort = port.getPort
        if (thisPort == myPort) then
          found = true
          return port
        end # match
      end #each site
    end # more than one

    if (!found) then
      newPort = PortNum.new(myPort)
      @myPortList << newPort
      return newPort
    end # found
  end # addPort

  def printPorts
    @myPortList.each do |portno|
      puts "port is #{portno.getPort}"
    end # Ports
  end #printPorts

end #ProcessName

### PortNum
class PortNum
  attr_accessor :port

  def initialize(port)
    @port = port
    @myConnects = []
    @graphNode
  end #initialize

  def getPort
    return(@port)
  end

  def addConnection(outPort)
    @myConnects << outPort
  end

  def setGraphNode(inNode)
    @graphNode = inNode
  end

  def getGraphNode
    return @graphNode
  end

  def getConnections
    return @myConnects
  end

end #PortNum

def FileInput(inputfile, outputfile, filetype, mySitename)
  @allComms = Array.new {Hash.new}
  $infiles = Array.new
  @inputfile = inputfile
  @outputfile = outputfile
  @filetype = filetype
  @mysitename = mySitename

  # this ss command lists processes to a file
  # comment out for a test file
  if @filetype == 'none'
    system ("ss -npatuw > #{@inputfile}")
    @filetype = 'newfile'
  end
  if @filetype == 'dir' then
    Dir.foreach(@inputfile) do |infile|
#      next if infile == '.' or infile == '..'
      if infile.end_with?('ss') then
        $infiles << @inputfile+'/'+infile
      end
    end
#   got through - check to ensure we got a file
    if $infiles.size == 0
       puts "no files found"
    end
#    @inputfile = infile+"_dir"
    @inputfile = @inputfile+"_dir"
    if @outputfile == nil then
      @outputfile = @inputfile
    end
  else
    $infiles << @inputfile
  end
  # get rid of any far away directories for our output files
  @outputfile = File.basename(@outputfile)

 # if new file, we need to convert the format
  if (@filetype == 'newfile') then
    counter = 0
    IO.foreach(@inputfile) do |line|
#     create a hash for all the significant info
      counter += 1
      sitename = ''
      domainname = ''
      hostname = ''
      localIP = ''
      localProc = ''
      peerIP = ''
      peerProc = ''
      proto = ''
      portName = ''
      pUser = ''

#     break out the fields
#       *** for npatuw ***
      begin
        cancel = false
        f1 = line.split(' ')
        state = f1[1]
        recQ = f1[2]
        if (recQ == "Recv-Q") then
          cancel = true
        end        
        sendQ = f1[3]
        localAdd = f1[4]
        peerAdd = f1[5]
        socketUsers = f1[6]
#       for the local address split address and proc via colon
        f2 = localAdd.split(':')
        localIP = f2[0]
        if localIP == "*" then
          localIP = "ALL"
        end
        localPort = f2[1]
        if (localIP == '' && localPort == '') then
          cancel = true
        end
#       for the dest address split address and proc via colon
        f3 = peerAdd.split(':')
        peerIP = f3[0]
        peerPort = f3[1]
#       create peer record and local record and associate the numbers
        f4 = socketUsers.split(':')
        proto = f4[1]
        f5 = proto.split('"')
        procName = f5[1]
        remain = f5[2]
        f6 = remain.split('=')
        pidplus = f6[1]
        f7 = pidplus.split(',')
        thePid = f7[0]
        pUser = `ps --no-header -o user #{thePid}`
      rescue
#       ignore everything else
      end
#     current site and host
      if (@mysitename == '') then
        sitename = "here"
      else
        sitename = @mysitename
      end
      hostname = "#{Socket.gethostname}"
      domainname = ''
  
#     write both sets to hashes
#    ignore header line
      if (!cancel) then
        $datarow = Hash.new
        $datarow["sitename"] = sitename
        $datarow["hostname"] = hostname
        $datarow["domainname"] = domainname
        $datarow["localIP"] = localIP
        $datarow["localPort"] = localPort
        if (procName != nil && pUser != nil) then
          $datarow["procname"] = "#{procName}\n#{pUser}"
        elsif (procName != nil) then
          $datarow["procname"] = procName
        elsif (pUser != nil)
          $datarow["procname"] = pUser
        else
          $datarow["procname"] = nil
        end  
        $datarow["processName"] = procName
        $datarow["puser"] = pUser.strip
        $datarow["peerIP"] = peerIP
        $datarow["peerPort"] = peerPort
        $datarow["socketUsers"] = socketUsers
        @allComms << $datarow
      end # useful line
    end   # end reading file
    printArray(@allComms, inputfile)
  else # not new file
  # read each input file in the directory
    $infiles.each do |infile|
      $numProcs = 0
      counter = 0
#     read the file, one line at a time
      IO.foreach(infile) do |line|
        begin
          cancel = false
          f1 = line.split(',')
          sitename = f1[0]
          hostname = f1[1]
          domainname = f1[2]
          localIP = f1[3]
          if localIP == "*" then
            localIP = "ALL"
          end
          localPort = f1[4]
          if (localIP == '' && localPort == '') then
            cancel = true
          end
          procName = f1[5]
          pUser = f1[6]
          peerIP = f1[7]
          peerPort = f1[8]
          socketUsers = ''
        rescue
#         ignore everything else
          puts "badly formatted file, ignoring line #{line}"
        end
#       current domain and host
        if (f1.size < 9) then
          puts "badly formatted file, ignoring line #{line}"
        else
          hostname = "#{Socket.gethostname}"
          domainname = ''
#         write both sets to hashes
          $datarow = Hash.new
          $datarow["sitename"] = sitename
          $datarow["hostname"] = hostname
          $datarow["domainname"] = domainname
          $datarow["localIP"] = localIP
          $datarow["localPort"] = localPort
        if (procName != nil && pUser != nil) then
          $datarow["procname"] = "#{procName}\n#{pUser}"
        elsif (procName != nil) then
          $datarow["procname"] = procName
        elsif (pUser != nil)
          $datarow["procname"] = pUser
        else
          $datarow["procname"] = nil
        end  
         $datarow["processName"] = procName
          $datarow["puser"] = pUser
          $datarow["peerIP"] = peerIP
          $datarow["peerPort"] = peerPort
          $datarow["socketUsers"] = socketUsers
          @allComms << $datarow
        end #enough fields
      end   # end reading file
    end # end array of files
  end # new file
  printArray(@allComms, @outputfile)
  return @allComms
end #FileInput

# Print array from file
def printArray(allComms, inputFile)
  puts "listing my file contents in #{inputFile}.ss"
  outFile = "#{inputFile}.ss"
  outfile = File.open(outFile, 'w')
  allComms.each do |record|
#    if ((record["peerPort"] != "*") && (record["peerPort"] != "Port"))
      outfile.puts "#{record["sitename"]},#{record["hostname"]},#{record["domainname"]},#{record["localIP"]},#{record["localPort"]},#{record["processName"]},#{record["puser"]},#{record["peerIP"]},#{record["peerPort"]}"
#    end
  end
end #printArray

# test
if __FILE__ == $0
# instantiate
# get the command line parameters
options = {}
$inpfile = nil
$outfile = nil
$mysitename = nil
optsparse = OptionParser.new do |opts|
  opts.banner = "Usage: ruby simp_processgraph.rb -s sitename [options]"
  opts.on('-h', '--help', 'Help') do
    puts opts
    exit
  end
  opts.on('-s', '--my site NAME', :required, 'Site Name (required!)') do
    |s| puts "mysitename is #{s}"
    $mysitename = s
  end
  opts.on('-i', '--input file NAME', 'Input file or directory name') do
    |i| puts "input filename is #{i}"
    $inpfile = i
  end
  out_msg =  'Outputfilename (will look for files in the directory named *.ss)'
  opts.on('-o', '--output file NAME', out_msg) do
    |o| puts "outfile is #{o}"
    $outfile = o
  end
end
optsparse.parse!
if ($mysitename == nil) then
  puts "Missing argument -s"
  puts optsparse.banner
  exit
end

theGraph = ProcessList.new($inpfile, $outfile)
theGraph.processData($inpfile, $outfile, $mysitename)

end # running this file or just required
