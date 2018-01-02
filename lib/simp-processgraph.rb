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

  def initialize(infile = nil,outfile = nil, raw = nil)
    @infile = infile
    @outfile = outfile
    @raw = raw
    @site_list = []
  end

# Process array from file
  def process_data(site_name, con_type)
    @inputfile = @infile
    @outputfile = @outfile
    @site_name = site_name
    @con_type = con_type

  # tell the user we got your back
    $stdout.puts "reading data"

  # get the list of processes to a file
    @rawtype = ".raw"
    @sstype = ".ss"
    infile = 'process_list'
    @filetype = 'none'

  # check to see if we input a file
    if @inputfile == nil
      @filetype = 'file'
      @inputfile = infile
    end

    if File.directory?@inputfile
      @filetype = 'dir'
    elsif ( (File.file?@inputfile) && ((File.extname(@inputfile)) == @sstype) )
      @filetype = 'file'
    elsif ( (File.file?@inputfile) && ((@raw == true) || (File.extname(@inputfile) == @rawtype)) )
#    elsif ( (File.file?@inputfile) && ((File.extname(@inputfile)) == @rawtype) )
      @filetype = 'raw'
    else
      infile = @inputfile
      @filetype = 'none'
    end

# output file
    if @outputfile == nil
      @outputfile = @inputfile
    end

    the_start = self

#   read from file
    data_read = file_input(@inputfile, @outputfile, @filetype, @site_name)

#   set up objects based on the record you just read
    data_read.each do |record|
      new_site = the_start.add_site(record["site_name"])
      new_host = new_site.add_host(record["hostname"])
      new_ip = new_host.add_ip(record["local_ip"])
#     jj 7/2/17
#     if we are on the www (firefox or chrome), let's just condense all those calls for now
      proc_name = record["proc_name"]
      port_name = record["local_port"]
      if (proc_name == 'firefox' or proc_name == 'chrome' or proc_name == 'browser')
        port_name = "local"
        proc_name = "browser"
      end
      new_proc = new_ip.add_proc(record["proc_name"])
      new_port = new_proc.add_port(port_name)
#     jj 7/2/17
#     destinations
#     dest_site = the_start.add_site(record["site_name"])
      if ( (record["peer_ip"]!= "*") && (record["peer_port"]!= "*"))
        dest_site = the_start.add_site("")
        dest_host = dest_site.add_host("")
        peer_proc = record["peer_proc"]
        if (proc_name == 'firefox' or proc_name == 'chrome' or proc_name == 'browser')
          dest_ip = dest_host.add_ip("www")
          dest_proc = dest_ip.add_proc("browser")
          dest_port = dest_proc.add_port("www")
        else
          dest_ip = dest_host.add_ip(record["peer_ip"])
          dest_proc = dest_ip.add_proc(record["peer_proc"])
          dest_port = dest_proc.add_port(record["peer_port"])
        end
        new_port.add_connection(dest_port)
        new_proc.add_connection(dest_proc)
        new_ip.add_connection(dest_ip)
      end
    end

    # Graph the things
    gv = Gv.digraph("ProcessGraph")
    # Nodes
    the_start.graph_processes(gv, @outputfile, @con_type)
    # Connectors
    the_start.graph_connections(gv, @outputfile, @con_type)
  end #process_data

  def add_site(site)
    found = false
    if (@site_list.size > 0)
      @site_list.each do |current_site|
        if current_site.site_name == site
          found = true
          return current_site
        end # match
      end #each site
    end # more than one site

    unless found
      add_site = SiteName.new(site)
      @site_list << add_site
      return add_site
    end
  end

  def printSites()
    @site_list.each do |site|
      puts "site name is #{site.site_name}"
      site.print_hosts
    end # site
  end #printSites

  def graph_processes(gv, outfile, con_type)
    outputfile = outfile
    # rank TB makes the graph go from top to bottom - works better right now with the CentOS version
    # rank LR draws left to right which is easier to read
    Gv.layout(gv, 'dot')
    Gv.setv(gv, 'rankdir', 'LR')
    Gv.setv(gv, 'splines', 'true')
    Gv.setv(gv, 'strict', 'true')
    # Gv.setv(gv, 'constraint', 'true') # test jj 12/11/17
    upno = 0
    sitecount = 0
    hostcount = 0
    ipcount = 0
    proccount = 0
    portcount = 0
#   progress through the sites
    @site_list.each do |sitenm|
      sitecount += 1
      sg = Gv.graph(gv, "cluster#{upno}")
      Gv.setv(sg, 'color', 'black')
      Gv.setv(sg, 'label', "#{sitenm.site_name}")
      Gv.setv(sg, 'shape', 'box')
      upno += 1
#     the hosts
      host_list = sitenm.host_list
      host_list.each do |host|
        hostcount += 1
        sgb = Gv.graph(sg, "cluster#{upno}")
        Gv.setv(sgb, 'color', 'red')
        Gv.setv(sgb, 'label', "#{host.hostname}")
        Gv.setv(sgb, 'shape', 'box')
        upno +=1
        ip_list = host.ip_list
        ip_list.each do |ip|
          ipcount += 1
          sgc = Gv.graph(sgb, "cluster#{upno}")
          Gv.setv(sgc, 'color', 'blue')
          Gv.setv(sgc, 'label', "#{ip.ip}")
          Gv.setv(sgc, 'shape', 'box')
          nga = Gv.node(sgc,"k#{upno}")
          Gv.setv(nga, 'label', "#{ip.ip}")
          Gv.setv(nga, 'style', 'filled')
          Gv.setv(nga, 'shape', 'point')
          Gv.setv(nga, 'color', 'white')
          Gv.setv(nga, 'width', '0.01')
          ip.graph_node = "k#{upno}"
          upno +=1
          if (con_type < 2)
            ip.proc_list.each do |_proc|
              proccount += 1
              sgd = Gv.graph(sgc, "cluster#{proccount}")
              Gv.setv(sgd, 'color', 'green')
              Gv.setv(sgd, 'label', "#{_proc.proc_name}")
              Gv.setv(sgd, 'shape', 'box')
              ngb = Gv.node(sgd,"k#{upno}")
              Gv.setv(ngb, 'label', "#{_proc.proc_name}")
              Gv.setv(ngb, 'style', 'filled')
              Gv.setv(ngb, 'shape', 'point')
              Gv.setv(ngb, 'color', 'white')
              Gv.setv(ngb, 'width', '0.01')
              _proc.graph_node = "k#{upno}"
              upno +=1
              if (con_type < 1)
                _proc.port_list.each do |portno|
                  portcount += 1
                  sge = Gv.graph(sgd, "cluster#{portcount}")
                  Gv.setv(sge, 'color', 'black')
                  Gv.setv(sge, 'label', "#{portno.port}")
                  Gv.setv(sge, 'shape', 'box')
                  ngc = Gv.node(sge,"k#{upno}")
                  Gv.setv(ngc, 'label', "#{portno.port}")
                  Gv.setv(ngc, 'style', 'filled')
                  Gv.setv(ngc, 'shape', 'point')
                  Gv.setv(ngc, 'color', 'white')
                  Gv.setv(ngc, 'width', '0.01')
                  portno.graph_node = "k#{upno}"
                  upno +=1
                end #ports
              end # if port
            end #proc_list
          end #if proc or port
        end #ip_list
      end #host_list
    end # site
  end #graph_processes

  def graph_connections (gv, outfile, con_type)
    line_array = Array.new
    start_end = Hash.new
#   con_type = 0 # port [T]
#   con_type = 1 # process [R]
#   con_type = 2 # ip [I]
    colors = Array['yellow','green','orange','violet', 'turquoise', 'gray','brown']
    count = 0
    outputfile = outfile

# tell the user what we're up to
    $stdout.puts "assembling graph"

#   progress through the sites
    @site_list.each do |sitenm|
      host_list = sitenm.host_list
      host_list.each do |host|
        ip_list = host.ip_list
        ip_list.each do |ip|

#       ip connections
          if (con_type == 2)
            ip.connections_i.each do |conn|
              start_node = ip.graph_node
              end_node = conn.graph_node
              if (end_node != nil && start_node != nil) then
                start_end = Hash.new
                start_end["start"] = start_node
                start_end["end"] = end_node
                line_array << start_end
              end  # not ''
            end #connections
          end # if ip connections

          proc_list = ip.proc_list
          proc_list.each do |myproc|

# processes
            if (con_type == 1)
              myproc.connections_r.each do |conn|
                start_node = myproc.graph_node
                end_node = conn.graph_node
                if (end_node != nil && start_node != nil) then
                  start_end = Hash.new
                  start_end["start"] = start_node
                  start_end["end"] = end_node
                  line_array << start_end
                end  # not ''
              end #connections
            end # if process connections


            port_list = myproc.port_list
            if (con_type == 0)
#             port connections
              port_list.each do |portnum|
                portnum.connections_t.each do |conn|
                  start_node = portnum.graph_node
                  end_node = conn.graph_node
                  if (end_node != nil && start_node != nil)
                     start_end = Hash.new
                     start_end["start"] = start_node
                     start_end["end"] = end_node
                     line_array << start_end
                  end  # not ''
                end #connections
              end #ports
            end # if port connections
          end #proc_list
        end #ip_list
      end #host_list
    end # site

# now just plot out the array of connections
    line_array.uniq!
    line_array.each do |start_end|
      count += 1
      start_node = start_end["start"]
      end_node = start_end["end"]
      colorcode =  count.modulo(colors.size)
      eg = Gv.edge(gv, start_node, end_node)
#     connect the dots
      Gv.setv(eg, 'color', colors[colorcode])
    end
    success = Gv.write(gv, "#{outputfile}.dot")
#   for now, create the dot this way, see if we can find correction
    #results = %x(dot -Tpng #{outputfile}.dot -o #{outputfile}.png)
    results = `dot -Tpng #{outputfile}.dot -o #{outputfile}.png 2> /dev/null`
    if $?.success? then
    else
      $stderr.puts "dot command failed"
    end
  end #graph_connections
end #ProcessList

### Site
class SiteName
  attr_reader :site_name, :host_list

  def initialize(site_name)
    @site_name = site_name
    @host_list = []
  end #initialize

  def add_host(new_host)
    found = false
    if (@host_list.size > 0)
      @host_list.each do |hostnm|
        if new_host == hostnm.hostname
          found = true
          return hostnm
        end # match
      end #each site
    end # more than one

    unless found
      host = HostName.new(new_host)
      @host_list << host
      return host
    end
  end

  def printHosts
    @host_list.each do |hostnm|
      puts "hostname is #{hostnm}"
      hostnm.print_ips
    end # site
  end #printHosts

end #SiteName

### Host
class HostName
  attr_reader :hostname, :ip_list

  def initialize(hostname)
    @hostname = hostname
    @ip_list = []
  end #initialize

  def add_ip(ip)
    found = false
    if (@ip_list.size > 0)
      @ip_list.each do |ipnm|
        if (ipnm.ip == ip)
          found = true
          return ipnm
        end # match
      end #each site
    end # more than one

    unless found
      new_ip = IPAddr.new(ip)
      @ip_list << new_ip
      return new_ip
    end # found
  end # add_ip

  def print_ips
    @ip_list.each do |ipnm|
      puts "ip is #{ipnm.ip}"
      ipnm.print_proc_list
    end # IP
  end #print_ips

end #HostName

### IP
class IPAddr
  attr_accessor :graph_node
  attr_reader :ip, :proc_list, :connections_i

  def initialize(ip)
    @ip = ip
    @connections_i = []
    @proc_list = []
    @graph_node = nil
  end #initialize

  def add_proc(proc_to_add)
    found = false
    if (@proc_list.size > 0)
      @proc_list.each do |_proc|
        if (_proc.proc_name == proc_to_add)
          found = true
          return _proc
        end # match
      end #each proc
    end # more than none

    unless found
      new_pl = ProcessName.new(proc_to_add)
      @proc_list << new_pl
      return new_pl
    end # found
  end # add_proc

  def print_proc_list
    @proc_list.each do |_proc|
      puts "proc is #{_proc.proc_name}"
      _proc.printPorts
    end # Proc
  end #print_proc_list

  def add_connection(ip_add)
     @connections_i << ip_add
  end

end #IPAddr

### Process
class ProcessName
  attr_accessor :graph_node
  attr_reader :proc_name, :port_list, :connections_r

  def initialize(proc_name)
    @proc_name = proc_name
    @proc_name.strip! if @proc_name
    @connections_r = []
    @port_list = []
  end #initialize

  def add_port(current_port)
    found = false
    if (@port_list.size > 0)
      @port_list.each do |port|
        if (port.port == current_port)
          found = true
          return port
        end # match
      end #each site
    end # more than one

    unless found
      new_port = PortNum.new(current_port)
      @port_list << new_port
      return new_port
    end # found
  end # add_port

  def printPorts
    @port_list.each do |port|
      puts "port is #{port.port}"
    end # Ports
  end #printPorts

  def add_connection(proc)
    @connections_r << proc
  end

end #ProcessName

### PortNum
class PortNum
  attr_accessor :graph_node
  attr_reader :port, :connections_t

  def initialize(port)
    @port = port
    @connections_t = []
    @graph_node
  end #initialize

  def add_connection(port)
    @connections_t << port
  end
end #PortNum

def file_input(inputfile, outputfile, filetype, site_name)
  @all_comms = Array.new {Hash.new}
  infiles = Array.new
  @inputfile = inputfile
  @outputfile = outputfile
  @filetype = filetype
  @site_name = site_name

  new_ss = false # set to true if we are running ss the first time to get the correct hostname

  # this ss command lists processes to a file
  # comment out for a test file
  if @filetype == 'none'
    @input1file = "#{@inputfile}#{@rawtype}"
    %x(ss -npatuw > #{@input1file})
    new_ss = true  # so we know to use our own hostname
    innewfiles = `pwd`.strip
    @inputfile = "#{innewfiles}\/"
    @filetype = 'dir'
    @raw = true
  end
  if @filetype == 'dir'
    if @raw == true
      Dir.foreach(@inputfile) do |infile|
        infile = infile
        if infile.end_with?(@rawtype)
          infiles << @inputfile+'/'+infile
        end
      end    
    else
      Dir.foreach(@inputfile) do |infile|
        if infile.end_with?(@sstype)
          infiles << @inputfile+'/'+infile
        end
      end
    end
#   got through - check to ensure we got a file
    if infiles.size == 0
       $stderr.puts "no files found"
    end
    @inputfile = @inputfile+"_dir"
    if @outputfile == nil
      @outputfile = @inputfile
    end
  else
    infiles << @inputfile
  end
  # get rid of any far away directories for our output files
  @outputfile = File.basename(@outputfile)

 # if new file, we need to convert the format
#  if (@raw == true) && (@filetype == 'dir')
  if (@raw == true)
    @file_counter = 0
# read each input file in the directory
    infiles.each do |infile|
      numProcs = 0
      @file_counter += 1
      justfile1 = File.basename(infile,@rawtype)
      p1 = justfile1.split('.')
      justfile = p1[0]
#     read the file, one line at a time
      IO.foreach(infile) do |line|
        line.strip!

#       create a hash for all the significant info
        #site_name = ''
        #if (new_ss) then
          @site_name = @site_name
        #else
          #@site_name = justfile
        #end
        domainname = ''
        hostname = ''
        local_ip = ''
        local_proc = ''
        peer_ip = ''
        peer_proc = ''
        proto = ''
        port_name = ''
        proc_user = ''

#       break out the fields
#       *** for npatuw ***
        begin
          cancel = false
          f1 = line.split(' ').map(&:strip)
          state = f1[1]
          rec_q = f1[2]
          if (rec_q == "Recv-Q")
            cancel = true
          end
          send_q = f1[3]
### judy is swapping the local and remote addresses if state is LISTEN or UNCONN 5/22/17
          if state == "LISTEN" or state == "UNCONN"
            local_add = f1[4] # BACK
            peer_add = f1[5]
          else
            local_add = f1[4]
            peer_add = f1[5]
          end
          socket_users = f1[6]
#         for the local address split address and proc via colon
          f2 = local_add.split(':').map(&:strip)
          local_ip = f2[0]
          if local_ip == "*"
            local_ip = "ALL"
          end
          local_port = f2[1]
          if (local_ip == '' && local_port == '')
            cancel = true
          end
#         for the dest address split address and proc via colon
          f3 = peer_add.split(':').map(&:strip)
          peer_ip = f3[0]
          peer_port = f3[1]
#         create peer record and local record and associate the numbers
          f4 = socket_users.split(':').map(&:strip)
          proto = f4[1]
          f5 = proto.split('"').map(&:strip)
          proc_name = f5[1]
          remain = f5[2]
          f6 = remain.split('=').map(&:strip)
          pidplus = f6[1]
          f7 = pidplus.split(',').map(&:strip)
          the_pid = f7[0]
          proc_user = %x(ps --no-header -o user #{the_pid}).strip
        rescue
#         ignore everything else
          # puts "error parsing #{infile} - badly formatted raw file, ignoring line #{line}"
        end
#       current domain and host
        if (f1.size < 7)
          # puts "not enough fields #{infile} - badly formatted raw file, ignoring line #{line}"
        end
#       current site and host
        #if (@site_name == '')
        #  site_name = "here"
        #else
          site_name = @site_name
        #end

# judy - get hostname from filename i we didnt just run the ss command
        if (new_ss) then
          hostname = "#{Socket.gethostname}"
        else
          host = File.basename(infile, ".*")
          hostname = File.basename(host, ".*")
        end

        domainname = ''
        peer_proc = ''

#       write both sets to hashes
#       ignore header line
        unless cancel
# if you are on the www, let's fix this now
         if (proc_name == 'firefox' or proc_name == 'chrome' or proc_name == 'browser')
            proc_name = "browser"
            local_port = "local"
            peer_ip = "www"
            peer_port = "www"
            peer_proc = "browser"
          end
          datarow = Hash.new
          datarow["site_name"] = site_name
          datarow["hostname"] = hostname
          datarow["domainname"] = domainname
          datarow["local_ip"] = local_ip
          datarow["local_port"] = local_port
          if proc_name != ''  && proc_user != ''
            datarow["proc_name"] = "#{proc_name}\n#{proc_user}"
          elsif proc_name
            datarow["proc_name"] = proc_name
          elsif (proc_user != '')
            datarow["proc_name"] = proc_user
          else
            datarow["proc_name"] = ''
          end
          datarow["process_name"] = proc_name
          datarow["process_user"] = proc_user.strip
          datarow["peer_ip"] = peer_ip
          datarow["peer_proc"] = peer_proc
          datarow["peer_port"] = peer_port
          datarow["socket_users"] = socket_users
          @all_comms << datarow
        end # useful line
      end   # end reading file
      print_array(@all_comms, @outputfile)
    #  return @all_comms
    end #file_input
    $stdout.puts "read #{@file_counter} files"
    return @all_comms
  else # not raw
  # read each input file in the directory
    @file_counter = 0
    infiles.each do |infile|
      justfile = File.basename(infile,@sstype)
      numProcs = 0
      @file_counter += 1
#     read the file, one line at a time
      IO.foreach(infile) do |line|
        line.strip!

        begin
          cancel = false
          f1 = line.split(',').map(&:strip)
          # judy sitename fix site_name = f1[0]
          hostname = f1[1]
          domainname = f1[2]
          local_ip = f1[3]
          if local_ip == "*"
            local_ip = "ALL"
          end
          local_port = f1[4]
          if (local_ip == '' && local_port == '')
            cancel = true
          end
          proc_name = f1[5]
          proc_user = f1[6]
          peer_ip = f1[7]
          peer_port = f1[8]
          socket_users = ''
          peer_proc = ''
        rescue
#         ignore everything else
          # puts "error parsing #{infile} - badly formatted ss file, ignoring line\n #{line}"
        end
#       current domain and host
        if (f1.size < 7)
          # puts "#{infile} not enough fields - badly formatted ss file, ignoring line\n #{line}"
        else
# if you are on the www, let's fix this now
         if (proc_name == 'firefox' or proc_name == 'chrome' or proc_name == 'browser')
            proc_name = "browser"
            local_port = "local"
            peer_ip = "www"
            peer_port = "www"
            peer_proc = "browser"
          end

# judy fix this to get the correct hostname - if brand new figure it out, if not, use the filename
          if new_ss
            hostname = "#{Socket.gethostname}"
          else
            host = File.basename(infile, ".*")
            hostname = File.basename(host, ".*")
          end

          domainname = ''
#         write both sets to hashes
          datarow = Hash.new
          datarow["site_name"] = site_name
# judy sitename fix          datarow["site_name"] = justfile
          datarow["hostname"] = hostname
          datarow["domainname"] = domainname
          datarow["local_ip"] = local_ip
          datarow["local_port"] = local_port
        if proc_name != '' && proc_user != ''
          datarow["proc_name"] = "#{proc_name}\n#{proc_user}"
        elsif proc_name
          datarow["proc_name"] = proc_name
        elsif proc_user
          datarow["proc_name"] = proc_user
        else
          datarow["proc_name"] = ''
        end
          datarow["process_name"] = proc_name
          datarow["process_user"] = proc_user
          datarow["peer_ip"] = peer_ip
          datarow["peer_port"] = peer_port
          datarow["socket_users"] = socket_users
          datarow["peer_proc"] = peer_proc
           @all_comms << datarow
        end #enough fields
      end   # end reading file
    end # end array of files
    $stdout.puts "read #{@file_counter} files"
  end # new file
  print_array(@all_comms, @outputfile)
  return @all_comms
end #file_input

# Print array from file
def print_array(all_comms, input_file)
  outFile = "#{input_file}.ss"
  outfile = File.open(outFile, 'w')
  all_comms.each do |record|
    outfile.puts "#{record["site_name"]},#{record["hostname"]},#{record["domainname"]},#{record["local_ip"]},#{record["local_port"]},#{record["process_name"]},#{record["process_user"]},#{record["peer_ip"]},#{record["peer_port"]},#{record["peer_proc"]}"
  end
end #print_array
