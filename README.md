# simp-processgraph
This holds the tool we are using to draw the process graphs

This code allows you to plot the communications between your host and others.

* It uses the `ss` (socket statistics) command with the `-npatuw` options
-n, --numeric    Do now try to resolve service names.
-a, --all    Display all sockets.
-p, --processes    Show process using socket.
-t, --tcp    Display only TCP sockets.
-u, --udp    Display only UDP sockets.
-w, --raw    Display only RAW sockets.
* It creates an array of hashes of (sitename, hostname, domainname, localIP, localPort, process, user, peerIP, peerPort, socketUsers),
and writes the interim data to a file,

* Then it creates a graph, boxing up site, host, IP, ports, and connecting to destinations.
Lines are color-alternated to keep them distinct.

In order to run, you must set up your environment as described in https://simp-project.atlassian.net/wiki/display/SD/Setting+up+your+build+environment

(until you install bundler)
then
`$bundle`

In order to create the .png files, you must have graphviz installed
```bash
sudo yum install graphviz
```
...and the ruby add-on to graphviz
```bash
sudo yum install graphviz-ruby
```
...and to ensure you can see the Ruby libraries, type:
```bash
export RUBYLIB=/usr/lib64/graphviz/ruby
```

Below are the functions available under rake:

```
rake chmod            # Ensure gemspec-safe permissions on all files
rake clean            # Remove any temporary products
rake clobber          # Remove any generated file
rake default          # default - help
rake help             # help
rake pkg:gem          # build rubygem package for simp-processgraph
rake pkg:install_gem  # build and install rubygem package for simp-processgraph
rake spec             # run all RSpec tests
```

To run the program, build and install the gem by running
`$ rake pkg:install_gem`

and run it
`$ processgraph -s [sitename]`

or:
type in the command below to run it right from the ruby:
`$ ruby simp-processgraph.rb`

The parameters are:

```
Usage: ruby simp_processgraph.rb [options]


    -h, --help                       Help

    -s, --my site  NAME              Name to associate with your site **(REQUIRED)**

    -i, --input filename NAME        Input file or directory name, properly formatted files will have the .ss filetype, generated from an earlier run

    -o, --output file NAME           Output file or directory name (will look for files in the given directory and subdirectories named *.ss)
```

Or, in your ruby, include the code:
`require simp_process.rb`

and call the two lines below:

```ruby
theGraph = ProcessList.new($inpfile, $outfile)
theGraph.processData($inpfile, $outfile, $sitename)
```

