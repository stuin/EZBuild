# EZBuild
Bash script for building and testing small projects with minimal configuration

# Config
The default config is designed for small c projects, using the g++ compiler.
However, by changing variables both globally and for a specific directory, any set of bash commands can be used.

### Inheritance
First priority is given to the local .includes file, followed by any listed parent file.
If a value is not found locally or in a parent, the global /etc/ezbuild file will be used.

### Merging
Some options will merge the local value and all parent values into a single varaible.
The global value will not be included when merging.
The files option will the relevant directory path to every token when merging.

Option	|Merging|Desc							|Vars
-----	|-----	|-----							|-----
files	|path	|lists all files passed to the build command		|
output	|none	|sets the output file given to the other commands	|
builder	|none	|first build command run				|files, output
buildargs|basic	|added to end of build command				|
linker	|none	|second build command run				|output
linkargs|basic	|added to end of link command				|
terminal|none	|emulator command used for -e 				|
tester 	|none	|command used with -r 					|output
testargs|basic	|added to end of test command 				|
parent  |none	|provides additional config file to check		|

# Install
First edit the included config file to match your personal system and use case.
Then run the install script.
sudo ./install.sh
