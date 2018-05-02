#!/usr/bin/env ruby
######################################
# simp-processgraph
# This code allows you to plot the communications between hosts.
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
# ...to ensure you can see the Ruby libraries, type (and/or add to .bashrc)
# export RUBYLIB=/usr/lib64/graphviz/ruby
#
###########################################
require 'optparse'
require 'gv'
require 'socket'

# ProcessList creates the list of processes from which we create a graph
class ProcessList
  attr_accessor :infile, :out_file

  def initialize(infile = nil, out_file = nil, raw = nil)
    @infile = infile
    @out_file = out_file
    @raw = raw
    @site_list = []
    @ip_conn = 2
    @proc_conn = 1
    @port_conn = 0
  end

  # Process array from file
  def process_data(site_name, con_type)
    @inputfile = @infile
    @outputfile = @out_file
    @site_name = site_name
    @con_type = con_type

    # tell the user we got your back
    $stdout.puts 'reading data'

    # get the list of processes to a file
    @rawtype = '.raw'
    @sstype = '.ss'
    infile = 'process_list'
    @filetype = 'none'

    # check to see if we input a file
    if @inputfile.nil? == true
      @filetype = 'file'
      @inputfile = infile
    end

    if File.directory? @inputfile
      @filetype = 'dir'
    elsif (File.file? @inputfile) && (File.extname(@inputfile) == @sstype)
      @filetype = 'file'
    elsif (File.file? @inputfile) && ((@raw == true) ||
      (File.extname(@inputfile) == @rawtype))
      @filetype = 'raw'
    else
      @filetype = 'none'
    end

    # output file
    @outputfile = @inputfile if @outputfile.nil?

    the_start = self

    # read from file
    data_read = file_input(@inputfile, @outputfile, @filetype, @site_name)

    # set up objects based on the record you just read
    data_read.each do |record|
      new_site = the_start.add_site(record['site_name'])
      new_host = new_site.add_host(record['hostname'])
      new_ip = new_host.add_ip(record['local_ip'])
      # if we are on the www (firefox or chrome), let's condense those calls
      proc_name = record['proc_name']
      port_name = record['local_port']
      if %w(firefox chrome browser).include?(proc_name)
        port_name = 'local'
        proc_name = 'browser'
      end
      new_proc = new_ip.add_proc(record['proc_name'])
      new_port = new_proc.add_port(port_name)
      # destinations
      next unless (record['peer_ip'] != '*') && (record['peer_port'] != '*')
      dest_site = the_start.add_site('')
      dest_host = dest_site.add_host('')
      peer_proc = record['peer_proc']
      if %w(firefox chrome browser).include?(proc_name)
        dest_ip = dest_host.add_ip('www')
        dest_proc = dest_ip.add_proc('browser')
        dest_port = dest_proc.add_port('www')
      else
        dest_ip = dest_host.add_ip(record['peer_ip'])
        dest_proc = dest_ip.add_proc(record['peer_proc'])
        dest_port = dest_proc.add_port(record['peer_port'])
      end
      new_port.add_connection(dest_port)
      new_proc.add_connection(dest_proc)
      new_ip.add_connection(dest_ip)
    end

    # Graph the things
    mygraph = Gv.digraph('ProcessGraph')
    # Nodes
    the_start.graph_processes(mygraph, @outputfile, @con_type)
    # Connectors
    the_start.graph_connections(mygraph, @outputfile, @con_type)
  end
  # end process_data

  def add_site(site)
    found = false
    unless @site_list.empty?
      @site_list.each do |current_site|
        if current_site.site_name == site
          found = true
          return current_site
        end
        # end match
      end
      # end site
    end
    # more than one site

    unless found
      add_site = SiteName.new(site)
      @site_list << add_site
      return add_site
    end
  end

  def print_sites(input_file)
    dbg_file = File.open(input_file, "w")
    @site_list.each do |site|
      dbg_file.puts "site name is #{site.site_name}"
      site.print_hosts(dbg_file)
    end
    # end site
  end
  # end print_sites

  def graph_processes(mygraph, _out_file, con_type)
    # rank TB makes the graph go from top to bottom
    # works better right now with the CentOS version
    # rank LR draws left to right which is easier to read
    Gv.layout(mygraph, 'dot')
    Gv.setv(mygraph, 'rankdir', 'LR')
    Gv.setv(mygraph, 'splines', 'polyline')
    Gv.setv(mygraph, 'concentrate', 'true')
    Gv.setv(mygraph,'ranksep','10.0')
    upno = 0
    sitecount = 0
    hostcount = 0
    ipcount = 0
    proccount = 0
    portcount = 0
    # progress through the sites
    @site_list.each do |sitenm|
      sitecount += 1
      sg = Gv.graph(mygraph, "cluster#{upno}")
      Gv.setv(sg, 'color', 'black')
      Gv.setv(sg, 'label', sitenm.site_name.to_s)
      Gv.setv(sg, 'shape', 'box')
      upno += 1
      # the hosts
      host_list = sitenm.host_list
      host_list.each do |host|
        hostcount += 1
        sgb = Gv.graph(sg, "cluster#{upno}")
        Gv.setv(sgb, 'color', 'red')
        Gv.setv(sgb, 'label', host.hostname.to_s)
        Gv.setv(sgb, 'shape', 'box')
        upno += 1
        ip_list = host.ip_list
        ip_list.each do |ip|
          ipcount += 1
          sgc = Gv.graph(sgb, "cluster#{upno}")
          Gv.setv(sgc, 'color', 'blue')
          Gv.setv(sgc, 'label', ip.ip.to_s)
          Gv.setv(sgc, 'shape', 'box')
          nga = Gv.node(sgc, "k#{upno}")
          Gv.setv(nga, 'label', ip.ip.to_s)
          Gv.setv(nga, 'style', 'filled')
          Gv.setv(nga, 'shape', 'point')
          Gv.setv(nga, 'color', 'white')
          Gv.setv(nga, 'width', '0.01')
          ip.graph_node = "k#{upno}"
          upno += 1
          next unless con_type < @ip_conn
          ip.proc_list.each do |theproc|
            proccount += 1
            sgd = Gv.graph(sgc, "cluster#{proccount}")
            Gv.setv(sgd, 'color', 'green')
            Gv.setv(sgd, 'label', theproc.proc_name.to_s)
            Gv.setv(sgd, 'shape', 'box')
            ngb = Gv.node(sgd, "k#{upno}")
            Gv.setv(ngb, 'label', theproc.proc_name.to_s)
            Gv.setv(ngb, 'style', 'filled')
            Gv.setv(ngb, 'shape', 'point')
            Gv.setv(ngb, 'color', 'white')
            Gv.setv(ngb, 'width', '0.01')
            theproc.graph_node = "k#{upno}"
            upno += 1
            next unless con_type < @proc_conn
            theproc.port_list.each do |portno|
              portcount += 1
              sge = Gv.graph(sgd, "cluster#{portcount}")
              Gv.setv(sge, 'color', 'black')
              Gv.setv(sge, 'label', portno.port.to_s)
              Gv.setv(sge, 'shape', 'box')
              ngc = Gv.node(sge, "k#{upno}")
              Gv.setv(ngc, 'label', portno.port.to_s)
              Gv.setv(ngc, 'style', 'filled')
              Gv.setv(ngc, 'shape', 'point')
              Gv.setv(ngc, 'color', 'white')
              Gv.setv(ngc, 'width', '0.01')
              portno.graph_node = "k#{upno}"
              upno += 1
            end
            # ports
            # if port
          end
          # proc_list
          # if proc || port
        end
        # ip_list
      end
      # host_list
    end
    # site
  end
  # end graph_processes

  def graph_connections(mygraph, out_file, con_type)
    line_array = []
    start_end = {}
    colors = Array['yellow', 'green', 'orange', 'violet',
                   'turquoise', 'gray', 'brown']
    count = 0
    outputfile = out_file

    # tell the user what we're up to
    $stdout.puts 'assembling graph'

    # progress through the sites
    @site_list.each do |sitenm|
      host_list = sitenm.host_list
      host_list.each do |host|
        ip_list = host.ip_list
        ip_list.each do |ip|
          # ip connections
          if con_type == @ip_conn
            ip.connections_i.each do |conn|
              start_node = ip.graph_node
              end_node = conn.graph_node
              next unless !end_node.nil? && !start_node.nil?
              start_end = {}
              start_end['start'] = start_node
              start_end['end'] = end_node
              line_array << start_end
              # not ''
            end
            # connections
          end
          # if ip connections

          proc_list = ip.proc_list
          proc_list.each do |myproc|
            # processes
            if con_type == @proc_conn
              myproc.connections_r.each do |conn|
                start_node = myproc.graph_node
                end_node = conn.graph_node
                next unless !end_node.nil? && !start_node.nil?
                start_end = {}
                start_end['start'] = start_node
                start_end['end'] = end_node
                line_array << start_end
                # not ''
              end
              # connections
            end
            # end if process connections

            port_list = myproc.port_list
            next unless con_type == @port_conn
            # port connections
            port_list.each do |portnum|
              portnum.connections_t.each do |conn|
                start_node = portnum.graph_node
                end_node = conn.graph_node
                next unless !end_node.nil? && !start_node.nil?
                start_end = {}
                start_end['start'] = start_node
                start_end['end'] = end_node
                line_array << start_end
                # not ''
              end
              # connections
            end
            # ports
            # if port connections
          end
          # proc_list
        end
        # ip_list
      end
      # host_list
    end
    # end site

    # now just plot out the array of connections
    line_array.uniq!
    line_array.each do |startend|
      count += 1
      start_node = startend['start']
      end_node = startend['end']
      colorcode = count.modulo(colors.size)
      eg = Gv.edge(mygraph, start_node, end_node)
      # connect the dots
      Gv.setv(eg, 'color', colors[colorcode])
    end
    Gv.write(mygraph, "#{outputfile}.dot")
    # for now, create the dot this way, see if we can find correction
    `dot -Tpng #{outputfile}.dot -o #{outputfile}.png 2> /dev/null`
    warn 'dot command failed' unless $?.success?
  end # graph_connections
end # ProcessList

### Site
class SiteName
  attr_reader :site_name, :host_list

  def initialize(site_name)
    @site_name = site_name
    @host_list = []
  end
  # initialize

  def add_host(new_host)
    found = false
    unless @host_list.empty?
      @host_list.each do |hostnm|
        if new_host == hostnm.hostname
          found = true
          return hostnm
        end
        # match
      end
      # each site
    end
    # more than one site

    unless found
      host = HostName.new(new_host)
      @host_list << host
      return host
    end
  end

  def print_hosts(dbg_file)
    @host_list.each do |hostnm|
      dbg_file.puts "hostname is #{hostnm.hostname}"
      hostnm.print_ips(dbg_file)
    end
    # site
  end
  # print_hosts
end
# SiteName

### Host
class HostName
  attr_reader :hostname, :ip_list

  def initialize(hostname)
    @hostname = hostname
    @ip_list = []
  end # initialize

  def add_ip(ip)
    found = false
    unless @ip_list.empty?
      @ip_list.each do |ipnm|
        if ipnm.ip == ip
          found = true
          return ipnm
        end # match
      end # each site
    end # more than one

    unless found
      new_ip = IPAddr.new(ip)
      @ip_list << new_ip
      return new_ip
    end # found
  end # add_ip

  def print_ips(dbg_file)
    @ip_list.each do |ipnm|
      dbg_file.puts "ip is #{ipnm.ip}"
      ipnm.print_proc_list(dbg_file)
    end # IP
  end # print_ips
end # HostName

### IP
class IPAddr
  attr_accessor :graph_node
  attr_reader :ip, :proc_list, :connections_i

  def initialize(ip)
    @ip = ip
    @connections_i = []
    @proc_list = []
    @graph_node = nil
  end
  # initialize

  def add_proc(proc_to_add)
    found = false
    unless @proc_list.empty?
      @proc_list.each do |theproc|
        if theproc.proc_name == proc_to_add
          found = true
          return theproc
        end
        # match
      end
      # each proc
    end
    # more than none

    unless found
      new_pl = ProcessName.new(proc_to_add)
      @proc_list << new_pl
      return new_pl
    end
    # found
  end
  # add_proc

  def print_proc_list(dbg_file)
    @proc_list.each do |theproc|
      dbg_file.puts "proc is #{theproc.proc_name}"
      theproc.print_ports(dbg_file)
    end
    # Proc
  end
  # end print_proc_list

  def add_connection(ip_add)
    @connections_i << ip_add
  end
end
# end IPAddr

### Process
class ProcessName
  attr_accessor :graph_node
  attr_reader :proc_name, :port_list, :connections_r

  def initialize(proc_name)
    @proc_name = proc_name
    @proc_name.strip! if @proc_name
    @connections_r = []
    @port_list = []
  end
  # initialize

  def add_port(current_port)
    found = false
    unless @port_list.empty?
      @port_list.each do |port|
        if port.port == current_port
          found = true
          return port
        end
        # match
      end
      # each site
    end
    # more than one

    unless found
      new_port = PortNum.new(current_port)
      @port_list << new_port
      return new_port
    end
    # found
  end
  # add_port

  def print_ports(dbg_file)
    @port_list.each do |port|
      dbg_file.puts "port is #{port.port}"
    end
    # ports
  end
  # print_ports

  def add_connection(proc)
    @connections_r << proc
  end
end
# ProcessName

### PortNum
class PortNum
  attr_accessor :graph_node
  attr_reader :port, :connections_t

  def initialize(port)
    @port = port
    @connections_t = []
    @graph_node
  end
  # initialize

  def add_connection(port)
    @connections_t << port
  end
end
# PortNum

def file_input(inputfile, outputfile, filetype, site_name)
  @all_comms = Array.new []
  infiles = []
  @inputfile = inputfile
  @outputfile = outputfile
  @filetype = filetype
  @site_name = site_name

  # set to true if we are running ss the first time to get the correct hostname
  new_ss = false # assume false at first

  # this ss command lists processes to a file
  # comment out for a test file
  if @filetype == 'none'
    @input1file = "#{@inputfile}#{@rawtype}"
    `ss -npatuw > #{@input1file}`
    new_ss = true # so we know to use our own hostname
    innewfiles = `pwd`.strip
    @inputfile = "#{innewfiles}\/"
    @filetype = 'dir'
    @raw = true
  end
  if @filetype == 'dir'
    if @raw == true
      Dir.foreach(@inputfile) do |infile|
        infile = infile
        infiles << @inputfile + '/' + infile if infile.end_with?(@rawtype)
      end
    else
      Dir.foreach(@inputfile) do |infile|
        infiles << @inputfile + '/' + infile if infile.end_with?(@sstype)
      end
    end

    # got through - check to ensure we got a file
    warn 'no files found' if infiles.empty?
    @inputfile += '_dir'
    @outputfile = @inputfile if @outputfile.nil?
  else
    infiles << @inputfile
  end

  # get rid of any far away directories for our output files
  @outputfile = File.basename(@outputfile)

  # if new file, we need to convert the format
  if @raw == true
    @file_counter = 0
    # read each input file in the directory
    infiles.each do |infile|
      @file_counter += 1
      # read the file, one line at a time
      IO.foreach(infile) do |line|
        line.strip!

        # create a hash for all the significant info
        @site_name = @site_name
        domainname = ''
        hostname = ''
        local_ip = ''
        proc_name = ''
        peer_ip = ''
        proc_user = ''

        # break out the fields
        # *** for npatuw ***
        begin
          cancel = false
          f1 = line.split(' ').map(&:strip)
          state = f1[1]
          rec_q = f1[2]
          cancel = true if rec_q == 'Recv-Q'
          # swap the local and remote addresses if state is LISTEN or UNCONN
          if ['LISTEN','UNCONN'].include?state
            local_add = f1[5] # BACK
            peer_add = f1[4]
          else
            local_add = f1[4]
            peer_add = f1[5]
          end
          socket_users = f1[6]
          # for the local address split address and proc via colon

          local_ip = local_add.rpartition(':').first
          local_ip = 'ALL' if (local_ip == '*') || (local_ip[0..1] == '::')
          local_port = local_add.rpartition(':').last
          cancel = true if local_ip == '' && local_port == ''
          cancel = true if (local_ip == '::1') || (local_ip == '127.0.0.1')

          # for the dest address split address and proc via colon
          peer_ip = peer_add.rpartition(':').first
          peer_ip = 'ALL' if (peer_ip == '*') || (peer_ip[0..1] == '::')
          cancel = true if (peer_ip == '::1') || (peer_ip == '127.0.0.1')
          peer_port = peer_add.rpartition(':').last

          # create peer record and local record and associate the numbers
          f4 = socket_users.split(':').map(&:strip)
          proto = f4[1]
          f5 = proto.split('"').map(&:strip)
          proc_name = f5[1]
          remain = f5[2]
          f6 = remain.split('=').map(&:strip)
          pidplus = f6[1]
          f7 = pidplus.split(',').map(&:strip)
          the_pid = f7[0]
          proc_user = `ps --no-header -o user #{the_pid}`.strip
        rescue StandardError
          # ignore everything else
          # puts "error parsing raw file #{infile}, ignoring line #{line}"
        end

        # current domain and host
        if f1.size < 7
          # $stdout.puts "not enough fields raw file #{infile}, ignoring line #{line}" # jjjjjjjjjjjjjjjjjj
        end
        # current site and host
        site_name = @site_name

        # get hostname from filename if we didnt just run the ss command
        if new_ss
          hostname = Socket.gethostname.to_s
        else
          host = File.basename(infile, '.*')
          hostname = File.basename(host, '.*')
        end

        # if it is a browser, we do not need all the gory details
        peer_proc = ''
        if %w(firefox chrome browser).include?(proc_name)
          proc_name = 'browser'
          local_port = 'local'
          peer_ip = 'www'
          peer_port = ''
          peer_proc = ''
        end

        # write both sets to hashes
        # ignore header line
        unless cancel
          # if you are on the www, let's fix this now
          datarow = {}
          datarow['site_name'] = site_name
          datarow['hostname'] = hostname
          datarow['domainname'] = domainname
          datarow['local_ip'] = local_ip
          datarow['local_port'] = local_port
          datarow['proc_name'] = if proc_name != '' && proc_user != ''
                                   "#{proc_name}\n#{proc_user}"
                                 elsif proc_name
                                   proc_name
                                 elsif proc_user != ''
                                   proc_user
                                 else
                                   ''
                                 end
          datarow['process_name'] = proc_name
          datarow['process_user'] = proc_user.strip
          datarow['peer_ip'] = peer_ip
          datarow['peer_proc'] = peer_proc
          datarow['peer_port'] = peer_port
          datarow['socket_users'] = socket_users
          @all_comms << datarow
        end
        # was it a useful line
      end
      # end reading file
      print_array(@all_comms, @outputfile)
    end
    # file_input

    $stdout.puts "read #{@file_counter} files"
    return @all_comms
  else # not raw
    # read each input file in the directory
    @file_counter = 0
    infiles.each do |infile|
      @file_counter += 1
      # read the file, one line at a time
      IO.foreach(infile) do |line|
        line.strip!

        begin
          f1 = line.split(',').map(&:strip)
          hostname = f1[1]
          domainname = f1[2]
          local_ip = f1[3]
          local_ip = 'ALL' if local_ip == '*'
          local_port = f1[4]
          proc_name = f1[5]
          proc_user = f1[6]
          peer_ip = f1[7]
          peer_port = f1[8]
          socket_users = ''
          peer_proc = ''
        rescue StandardError
          # ignore everything else
          # $stdout.puts "error parsing #{infile} - ignoring\n #{line}"
        end
        # current domain and host

        if f1.size < 7
          # puts "#{infile} not enough fields - ignoring\n #{line}"
        else
          # if you are on the www, let's fix this now
          if %w(firefox chrome browser).include?(proc_name)
            proc_name = 'browser'
            local_port = 'local'
            peer_ip = 'www'
            peer_port = 'www'
            peer_proc = 'browser'
          end

          # fix this to get the correct hostname
          # if brand new figure it out, if not, use the filename
          if new_ss
            hostname = Socket.gethostname.to_s
          else
            host = File.basename(infile, '.*')
            hostname = File.basename(host, '.*')
          end

          # write both sets to hashes
          datarow = {}
          datarow['site_name'] = site_name
          datarow['hostname'] = hostname
          datarow['domainname'] = domainname
          datarow['local_ip'] = local_ip
          datarow['local_port'] = local_port
          datarow['proc_name'] = if proc_name != '' && proc_user != ''
                                   "#{proc_name}\n#{proc_user}"
                                 elsif proc_name
                                   proc_name
                                 elsif proc_user
                                   proc_user
                                 else
                                   ''
                                 end
          datarow['process_name'] = proc_name
          datarow['process_user'] = proc_user
          datarow['peer_ip'] = peer_ip
          datarow['peer_port'] = peer_port
          datarow['socket_users'] = socket_users
          datarow['peer_proc'] = peer_proc
          @all_comms << datarow
        end
        # enough fields
      end
      # end reading file
    end
    # end array of files
    $stdout.puts "read #{@file_counter} files"
  end
  # new file
  print_array(@all_comms, @outputfile)
  # return @all_comms
end
# file_input

# Print array from file
def print_array(all_comms, input_file)
  out_file = "#{input_file}.ss"
  out_file = File.open(out_file, "w")
  all_comms.each do |record|
    out_file.puts "#{record['site_name']},#{record['hostname']},
    #{record['domainname']},#{record['local_ip']},#{record['local_port']},
    #{record['process_name']},#{record['process_user']},#{record['peer_ip']},
    #{record['peer_port']},#{record['peer_proc']}"
  end
end
# end print_array
