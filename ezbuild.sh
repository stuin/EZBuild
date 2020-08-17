# Starting config locations
BASE=.includes
GLOBAL=/etc/ezbuild

EMULATOR=""
PAUSE=""
TEST=""
EXTRA=""

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
				echo "$out" | sed 's:""::' | tr '\n' ' '
			fi
		fi

		# Locate next config file if needed
		if [ "$file" != "$GLOBAL" ] && ( [ -z "$out" ] || [ -n "$2" ] ); then
			file=$(sed -n 's:parent=::p' $file)

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
	found=""

	# Get relevant files and relative location
	dir=$(dirname $file)
	list=$(echo $(cat $file | sed -n "$depfinder" | sed -z "s:\"\\n: :g"))

	# If a header file is newer than cache
	for val in $list; do
		if [ -e "$dir/$val" ]; then
			if [[ "$checked" != *"$dir/$val"* ]]; then
				h=$(headers "$depfinder" "$cachefile" "$dir/$val" "$checked")
				checked="$checked $h $dir/$val"
				if [ "$dir/$val" -nt "$cachefile" -o -n "$h" ]; then
					echo -n "$dir/$val "
					found="true"
				fi
			fi
		fi
	done
	echo ""
}

# Parse command arguments
while getopts ":epra:" options; do
    case "${options}" in
    e )
        EMULATOR="-e"
        ;;
    p )
		PAUSE="-p"
		;;
	t )
		TEST="-t"
		;;
	a )
		EXTRA=$OPTARG
		;;
	\?)
	    ;;
    esac
done

shift $((OPTIND -1))
EXTRA="$EXTRA $@"

# Redirect command to new window
if [ -n "$EMULATOR" ]; then
	$(grab terminal) ezbuild $PAUSE $TEST $EXTRA
	exit 0
fi

if [ -n "$TEST" ]; then
	# Run latest build
	runcmd=$(echo $(grab tester) | sed "s:%output:$(grab output):")
	rundir=$(grab testdir)
	cd $rundir
	$runcmd $EXTRA $(grab testargs 1)
else
	# Retrieve config for actual build
	files=$(echo " $(echo $(grab files 2))" | sed "s: ./: :g")
	output=$(grab output)
	num=$(grab num)

	# Run caching reg on files
	caching=$(grab caching)
	cached=$(echo $files | sed "$caching")
	depfinder=$(grab depfinder)

	# Remove cached items from file list
	if [ -n "$caching" ]; then
		IFS=' '
		for val in $files; do
			cacheval=$(echo " $val" | sed "$caching ; s:^ ::")
			# If source or header files newer than cache
			if [ -e "$cacheval" -a "$val" -ot "$cacheval" ]; then
				echo "Checking headers for $val"
				h=$(headers "$depfinder" "$cacheval" "$val")
				if [ -z "$h" ]; then
					files=$(echo $files | sed "s:$val::g")
				else
					echo $h
				fi
			fi
		done
	fi

	# Check if all files in cache
	echo ""
	if [ -z "$files" -a -n "$cached" ]; then
		echo "No files changed"
	else
		# Run build commands 1 through num
		for ((i=1; i <= $num; i++)); do

			# Retrive numbered command
			buildcmd=$(grab builder$i)
			buildargs=$(grab buildargs$i 1)

			# Retrive unnumbered command
			if [ "$i" == "1" -a -z "$buildcmd" ]; then
				buildcmd=$(grab builder)
				buildargs=$(grab buildargs 1)
			fi

			# Run command with substitutions
			buildcmd=$(echo $buildcmd | sed "s:%files:$files: ; s:%cached:$cached: ; s:%output:$output:")
			echo "$buildcmd$buildargs"
			$buildcmd $buildargs
		done
	fi

	chmod +x $output
fi

# Pause at end
if [ -n "$PAUSE" ]; then
	echo "Press enter to continue "
	read
fi
