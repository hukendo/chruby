. ./test/helper.sh

function test_chruby_export_no_arguments()
{
	chruby-export 2>/dev/null

	assertEquals "did not exit with 1" 1 $?
}


function test_chruby_exec_with_version()
{
	local output=$(chruby-export --version)

	assertEquals "did not output the correct version" \
		     "chruby version $CHRUBY_VERSION" \
		     "$output"
}

SHUNIT_PARENT=$0 . $SHUNIT2
