# Download #

## Download archive ##
You can download the latest package of the tool from
> http://code.google.com/p/jp-parser/downloads/list
To extract the archive, run
> `tar -xf jp_parser-0.8.tar.gz`

## Download from SVN ##
To download the latest version from the svn repository, run
> `svn checkout http://jp-parser.googlecode.com/svn/trunk/`

# Run the tool #

You can run the tool direct with:
> `./jp_parser <configfile>`

For additional options, see:
> `./jp_parser --help`

# Installation #
## Linux-specific ##

Note: The following commands require `make`. Most Linux-distributions should have this, Windows not.

To create the manpages of the tool, run
> `make documentation`
The manpages are in created in the directory ./doc.

To install the tool, run as root
> `make install`
This creates the manpages and installs the programm.
The current directory is still needed, "make install" just creates one symbolic link and installs the documentation!
The makefile tries to find the correct path for everything, but may need some help.
The makefile creates the file `/usr/bin/jp_parser`. To install this file to another path, just run
> `make bin=/your/bin/path install`

The manpages should be installed according your $MANPATH-Setting.
To specifiy another path, run
> `make mandir=/your/man/path install`

To remove the tool, run
> `make clean`

