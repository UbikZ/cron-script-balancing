#!/bin/bash

MAX_INSTANCE=2
NUMBER_OF_CHILD=4
CHILD_COMMAND="/path/to/cmd/mycmd.php"

# We need pidof command to manage number of instance easily
[[ ! `which pidof | grep "not found" | wc -l` -eq 0 ]] && echo "No pidof installed. Exiting." && exit

INSTANCE_COUNT=$(pidof -x $0 | wc -w)
CHILDREN_PIDS=""

# Start our children
if [[ $INSTANCE_COUNT -le $(($MAX_INSTANCE +1)) ]]; then

        for i in `seq $NUMBER_OF_CHILD`
        do
                echo "Starting child #$i"
                $CHILD_COMMAND &
                CHILDREN_PIDS="$CHILDREN_PIDS $!"
                # Clean quit on interupt and term signals
                trap "echo 'Killing children'; kill -9 $CHILDREN_PIDS; exit;" SIGINT SIGTERM
        done

	# Now wait for them
	# We will manipulate an array
	running_pids=( $CHILDREN_PIDS )
	while  [[ ${#running_pids[@]} -gt 0 ]] ; do
		for i in $(seq 0 $((${#running_pids[@]} -1))); do
			# Is this process still running ?
			ps -lfp ${running_pids[$i]} >/dev/null;
			if [[ $? -eq 0 ]]; then
				echo "Process ${running_pids[$i]} still running..."
			else
				echo "Process ${running_pids[$i]} is terminated."
				# Need to find a better way to rearrange array
				unset running_pids[$i]
				CHILDREN_PIDS=${running_pids[@]:0}
				trap "echo 'Killing children'; kill -9 $CHILDREN_PIDS; exit;" SIGINT SIGTERM
			fi
		done
		if [[ ${#running_pids[@]} -gt 0 ]]; then
			sleep 10
		fi
		running_pids=( $CHILDREN_PIDS )
	done

	echo "All done."

else
	echo "Allready enough instance"
fi
