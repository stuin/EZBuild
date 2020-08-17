# EZBuild
Bash script for building and testing small projects with minimal configuration

# Config
The default config is designed for small c projects, using the g++ compiler.
However, by changing variables both globally and for a specific directory, any ordered set of bash commands can be used.

### Inheritance
First priority is given to the local .includes file, followed by any listed parent file.
If a value is not found locally or in a parent, the global /etc/ezbuild file will be used.

### Merging
Some options will merge the local value and all parent values into a single varaible.
A value in the global config will not be included when merging.
The files option will include the relevant directory path to every token when merging.

### Other Options
Multiple build commands can be used, and the script will run through from 1-num.
build commands without a number will be counted as build1.

Option	|Merging|Desc							|Vars
-----	|-----	|-----							|-----
files	|path	|lists all files passed to the build command		|
output	|none	|sets the output file given to the other commands	|
num		|none	|number of build commands to run			|
builder\#	|none	|build command run						|%files, %cached, %output
buildargs\#	|basic	|added to end of build command			|
caching |none	|sed regex to convert src file paths to cached versions 	|
depfinder|none	|sed -n regex for locating the dependencies of a src file 	|
terminal|none	|emulator command used for -e 				|
tester 	|none	|command used with -r 						|%output
testargs|basic	|added to end of test command 				|
testdir	|basic	|directory to run test from 				|
parent  |none	|provides additional config file to check	|

# Install
First edit the included config file to match your personal system and use case.
Then run the install script.
```
sudo ./install.sh
```
