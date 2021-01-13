
########### UTILS FOR DEVELOPMENT #################

function buildloop_run() {
	clear && cargo build && echo OK
}

function buildloop() {
    while true; do
    	date
    	nc -l 7777
      bash -c "source build.sh && buildloop_run"
    done
}

########### UTILS FOR TESTING ######################


function test_fail() {
	cat << EOF | bash
	echo
	echo
	echo "$(tput setaf 1)****************************************$(tput sgr0)"
	echo "$(tput setaf 1)************* Test failed **************$(tput sgr0)"
	echo "$(tput setaf 1)****************************************$(tput sgr0)"
	exit 1
EOF
}

function test_passed() {
	echo
	echo
	echo "$(tput setaf 2)****************************************$(tput sgr0)"
	echo "$(tput setaf 2)************* Test passed **************$(tput sgr0)"
	echo "$(tput setaf 2)****************************************$(tput sgr0)"
}


function run_integration_test(){
	dir=$1
	echo "Running tests in $dir"

	export RUST_LOG="DEBUG"
	export RUST_BACKTRACE=1

	sudo -E kbct remap -c "$dir/conf.yaml" &
	kbct_pid=$!

	sudo -E kbct test-replay -t "$dir/test.txt"
	test_status=$?

	sudo kill "$kbct_pid"
	wait "$kbct_pid"

	unset RUST_LOG
	unset RUST_BACKTRACE

	[[ test_status -eq "0" ]] && \
	 echo "$(tput setaf 2)Passed test "$dir"$(tput sgr0)" || \
	 (echo "Error in test $dir" && test_fail)

}

function run_all_integration_tests() {
	for dir in ./tests/*; do
		echo "$dir"
		run_integration_test "$dir"
	done && \
  test_passed

}

function run_all_tests() {
	(cargo test || test_fail) && \
	run_all_integration_tests
}