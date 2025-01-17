#!/bin/bash

# Starting config locations
BASE=.includes
GLOBAL=/etc/ezbuild

EMULATOR=""
PAUSE=""
TEST=""
CACHED=""
EXTRA=""
NUMBER=""
OPEN=""
FILE=""

# Retrieve variable from recursive config files
grab() {
	out=""
	file=$BASE
	dir=""

	if [ -n "$2" ] && [ "$2" == "2" ]; then
		dir="true"
	fi

	# If no local config provided
	if [ ! -r "$file" ]; then
		file=$GLOBAL
		dir=""
	fi

	while [ -r "$file" ]; do
		out=$(sed -n "s:^$1=::p" $file)

		# Return config option
		if [ -n "$out" ]; then
			if [ -n "$dir" ]; then
				# Define path to current dir for each file
				dir=$(dirname $file)/
				echo "$dir$out" | sed "s: : $dir:g ; s:\"\"::g" | tr '\n' ' '
			else
				# Just append option
				echo "$out" | sed "s:\"\"::" | tr '\n' ' '
			fi
		fi

		# Locate next config file if needed
		if [ "$file" != "$GLOBAL" ] && ( [ -z "$out" ] || [ -n "$2" ] ); then
			file=$(sed -n "s:parent=::p" $file)

			# Fallback to global file
			if [ -z "$file" ] && ( [ -z "$dir" ] || [ "$dir" == "true" ] ) ; then
				file=$GLOBAL
				dir=""
			fi
		else
			file=""
		fi
	done
	echo ""
}

headers() {
	depfinder=$1
	cachefile=$2
	file=$3
	checked=$4

	# Get relevant files and relative location
	dir=$(dirname $file)
	list=$(echo $(cat $file | sed -n "$depfinder" | sed -z "s:\"\\n: :g"))

	# Search linked header files
	for val in $list; do
		if [ -e "$dir/$val" ]; then
			if [[ "$checked" != *"$dir/$val"* ]]; then
				# Recursive search
				h=$(headers "$depfinder" "$cachefile" "$dir/$val" "$checked")
				checked="$checked $h $dir/$val"
				if [ -n "$h" ]; then
					echo -n "$h"
				fi

				# Check if header is newer
				if [ "$dir/$val" -nt "$cachefile" ]; then
					echo -n "$dir/$val "
				fi
			fi
		fi
	done
	echo ""
}

# Parse command arguments
while getopts ":eprca:n:o:f:" options; do
    case "${options}" in
    e )
        EMULATOR="-e";;
    p )
		PAUSE="-p";;
	r )
		TEST="-r";;
	c )
		CACHED="-c";;
	a )
		EXTRA=$OPTARG;;
	n )
		NUMBER=$OPTARG;;
	o )
		OPEN=$OPTARG;;
	f )
		if [ -e "$BASE" ]; then
			BASE=$OPTARG
			FILE="-f"
		else
			echo "Selected config file not found"
			exit 1
		fi;;
	\?)
	    ;;
    esac
done

shift $((OPTIND -1))
EXTRA="$EXTRA $@"

# Test for open config file
if [ -z "$FILE" ] && echo "$OPEN" | grep -q -E '\.*includes$'; then
	BASE=$OPEN
fi

# Check for config in parent dir
if [ ! -e "$BASE" ]; then
	if [ -e "../$BASE" ]; then
		echo "Using parent dir config"
		cd ../
	else
		echo "Using global config"
	fi
fi

# Redirect command to new window
if [ -n "$EMULATOR" ]; then
	if [ -n "$NUMBER" ]; then
		NUMBER="-n $NUMBER"
	fi
	if [ -n "$OPEN" ]; then
		OPEN="-o $OPEN"
	fi
	FILE="-f $BASE"

	$(grab terminal) ezbuild $PAUSE $TEST $CACHED $NUMBER $OPEN $FILE $EXTRA
	exit 0
fi

cd $(grab cd)
caching=$(grab caching)
OPENC=$(echo " $OPEN" | sed "$caching")

if [ -n "$TEST" ]; then
	# Run latest build
	runcmd=$(echo $(grab tester) | sed "s:%output:$(grab output): ; s:%openc:$OPENC: ; s:%open:$OPEN:")
	runargs=$(grab testargs 1)
	rundir=$(grab testdir)
	cd $rundir
	echo "$runcmd $EXTRA $runargs"
	$runcmd $EXTRA $runargs
else
	# Retrieve config for actual build
	#shopt -s extglob
	files=$(echo " $(echo $(grab files 2))")
	output=$(grab output)
	num=$(grab num)

	# Run caching regex on files
	cached=$(echo " $files" | sed "$caching")
	depfinder=$(grab depfinder)
	filesc=$files

	echo "$files"

	# Remove cached items from file list
	if [ -n "$CACHED" ]; then
		if [ -n "$caching" ]; then
			IFS=' '
			for val in $filesc; do
				cacheval=$(echo " $val" | sed "$caching ; s:^ ::")
				# If source or header files newer than cache
				if [ -e "$cacheval" -a "$val" -ot "$cacheval" ]; then
					echo "Checking headers for $val"
					h=$(headers "$depfinder" "$cacheval" "$val")
					if [ -z "$h" ]; then
						filesc=$(echo $filesc | sed "s:$val::g")
					else
						echo $h
					fi
				fi
			done
		fi
	fi

	echo ""

	# Run build commands 1 through num
	for (( i=1; i<=$num; i++ )); do
		if [ -z "$NUMBER" -o "$i" == "$NUMBER" ]; then

			# Retrive numbered command
			buildcmd=$(grab builder$i)
			buildargs=$(grab buildargs$i 1)

			# Retrive unnumbered command
			if [ "$i" == "1" -a -z "$buildcmd" ]; then
				buildcmd=$(grab builder)
				buildargs=$(grab buildargs 1)
			fi

			# Run command with substitutions
			buildcmd=$(echo $buildcmd | sed "s:%ncfiles:$filesc: ; s:%files:$files: ; s:%cached:$cached: ; s:%output:$output: ; s:%openc:$OPENC:g ; s:%open:$OPEN:g")
			echo "$buildcmd$buildargs"
			$buildcmd $buildargs
		fi
	done
fi

# Pause at end
if [ -n "$PAUSE" ]; then
	echo "Press enter to continue "
	read
fi
