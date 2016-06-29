. ./test/helper.sh

function test_chruby_rubies_show_path(){
  chruby-rubies -p | grep $test_ruby_root >/dev/null
  assertEquals "no show path" "0" "$?"
}

SHUNIT_PARENT=$0 . $SHUNIT2
