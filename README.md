# SwiftHelloGtkBuilder
A simple 'hello-world' GtkBuilder app using SwiftGtk

## Building
Make sure you have all the prerequisites installed (see below).  After that, you can simply clone this repository and build the command line executable (be patient, this will download all the required dependencies and take a while to compile) using

	git clone https://github.com/rhx/SwiftHelloGtkBuilder.git
	cd SwiftHelloGtkBuilder
	./build.sh
	
After that, you can run the program using

	.build/debug/HelloGtkBuilder

A simple, empty 'Hello World' window should appear.  To exit the program, click the close button or press Control-C in the Terminal window.

### Application Bundler

On macOS, there is also an app bundle that gets created and can be opened directly:

	open .build/app/HelloGtkBuilder.app

This bundle is self-contained and you can move it to your `Applications` folder (or wherever it suits you), e.g.:

	mv .build/app/HelloGtkBuilder.app /Applications

### Xcode

On macOS you can also build the project using Xcode instead (but there is no full macOS app target yet, only a command-line executable).  To do this, you need to create an Xcode project first, then open the project in the Xcode IDE:


	./xcodegen.sh
	open HelloGtkBuilder.xcodeproj

After that, select the executable target (not the Bundle/Framework target with the same name as the executable) and use the (usual) Build and Run buttons to build/run your project.


## Prerequisites

### Swift

Building should work with both Swift 4 and Swift 3 (you need at least Swift 3.1). You can download Swift from https://swift.org/download/ -- if you are using macOS, make sure you have the command line tools installed as well).  Test that your compiler works using `swift --version`, which should give you something like

	$ swift --version
	Apple Swift version 4.0 (swiftlang-900.0.65 clang-900.0.37)
	Target: x86_64-apple-macosx10.9

on macOS, or on Linux you should get something like:

	$ swift --version
	Swift version 4.0 (swift-4.0-RELEASE)
	Target: x86_64-unknown-linux-gnu

### Gtk 3.18 or higher

The Swift wrappers have been tested with glib-2.46, 2.48, 2.52 and 2.54, and gdk/gtk 3.18, 3.20, and 3.22.  They should work with higher versions, but YMMV.  Also make sure you have `gobject-introspection` and its `.gir` files installed.

#### Linux

On Ubuntu 16.04, you can use the gtk that comes with the distribution.  Just install with the `apt` package manager:

	sudo apt update
	sudo apt install libgtk-3-dev gir1.2-gtksource-3.0 gobject-introspection libgirepository1.0-dev libxml2-dev

If you prefer a newer version of gtk, you can also install it from the GNOME 3 Staging PPA (see https://launchpad.net/~gnome3-team/+archive/ubuntu/gnome3-staging), but be aware that this can be a bit dangerous (as this removes packages that can be vital, particularly if you use a GNOME-based desktop), so only do this if you know what you are doing:

	sudo add-apt-repository ppa:gnome3-team/gnome3-staging
	sudo apt update
	sudo apt dist-upgrade
	sudo apt install libgtk-3-dev gir1.2-gtksource-3.0 gobject-introspection libgirepository1.0-dev libxml2-dev

#### macOS

On macOS, you can install gtk using HomeBrew (for setup instructions, see http://brew.sh).  Once you have a running HomeBrew installation, you can use it to install a native version of gtk:

	brew update
	brew install gtk+3



## Troubleshooting
Here are some common errors you might encounter and how to fix them.

### Old Swift toolchain or Xcode
If you get an error such as

	$ ./build.sh 
	error: unable to invoke subcommand: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-package (No such file or directory)
	
this probably means that your Swift toolchain is too old.  Make sure the latest toolchain is the one that is found when you run the Swift compiler (see above).

  If you get an older version, make sure that the right version of the swift compiler is found first in your `PATH`.  On macOS, use xcode-select to select and install the latest version, e.g.:

	sudo xcode-select -s /Applications/Xcode.app
	xcode-select --install

