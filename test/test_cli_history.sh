#!/bin/bash
# Basic CLI history test

# Magic line must be first in script (see README.md)
s="$_" ; . ./lib.sh || if [ "$s" = $0 ]; then exit 0; else return 0; fi

APPNAME=example

# include err() and new() functions and creates $dir

cfg=$dir/conf_yang.xml
histfile=$dir/histfile

# Use yang in example

cat <<EOF > $cfg
<clixon-config xmlns="http://clicon.org/config">
  <CLICON_CONFIGFILE>$cfg</CLICON_CONFIGFILE>
  <CLICON_YANG_DIR>/usr/local/share/clixon</CLICON_YANG_DIR>
  <CLICON_YANG_DIR>$IETFRFC</CLICON_YANG_DIR>
  <CLICON_YANG_MODULE_MAIN>clixon-example</CLICON_YANG_MODULE_MAIN>
  <CLICON_BACKEND_DIR>/usr/local/lib/$APPNAME/backend</CLICON_BACKEND_DIR>
  <CLICON_CLISPEC_DIR>/usr/local/lib/$APPNAME/clispec</CLICON_CLISPEC_DIR>
  <CLICON_CLI_DIR>/usr/local/lib/$APPNAME/cli</CLICON_CLI_DIR>
  <CLICON_CLI_MODE>$APPNAME</CLICON_CLI_MODE>
  <CLICON_CLI_HIST_FILE>$histfile</CLICON_CLI_HIST_FILE>
  <CLICON_CLI_HIST_SIZE>10</CLICON_CLI_HIST_SIZE>
  <CLICON_SOCK>/usr/local/var/$APPNAME/$APPNAME.sock</CLICON_SOCK>
  <CLICON_BACKEND_PIDFILE>/usr/local/var/$APPNAME/$APPNAME.pidfile</CLICON_BACKEND_PIDFILE>
  <CLICON_CLI_GENMODEL_COMPLETION>1</CLICON_CLI_GENMODEL_COMPLETION>
  <CLICON_XMLDB_DIR>/usr/local/var/$APPNAME</CLICON_XMLDB_DIR>
  <CLICON_XMLDB_PLUGIN>/usr/local/lib/xmldb/text.so</CLICON_XMLDB_PLUGIN>
</clixon-config>
EOF

cat <<EOF > $histfile
first line
EOF

# NOTE Backend is not really use here
new "test params: -f $cfg"
if [ $BE -ne 0 ]; then
    new "kill old backend"
    sudo clixon_backend -z -f $cfg
    if [ $? -ne 0 ]; then
	err
    fi
    new "start backend -s init -f $cfg"
    start_backend -s init -f $cfg

    new "waiting"
    sleep $RCWAIT
fi

new "cli read and add entry to existing history"
expecteof "$clixon_cli -f $cfg" 0 "example 42" "data"

new "Check histfile exists"
if [ ! -f $histfile ]; then
    err "$histfile" "not found"
fi

new "Check it has two entries"
lines=$(cat $histfile | wc -l)
if [ $lines -ne 2 ]; then
    err "Line:$lines" "2"
fi

new "check it contains first line"
nr=$(grep -c "example 42" $histfile)
if [ $nr -ne 1 ]; then
    err "Contains: example 42" "1"
fi

new "Check it contains example 42"
nr=$(grep -c "example 42" $histfile)
if [ $nr -ne 1 ]; then
    err "Contains: example 42" "1"
fi

new "cli add entry and create newhist file"
expecteof "$clixon_cli -f $cfg -o CLICON_CLI_HIST_FILE=$dir/newhist" 0 "example 43" "data"

new "Check newhist exists"
if [ ! -f $dir/newhist ]; then
    err "$dir/newhist" "not found"
fi

new "check it contains example 43"
nr=$(grep -c "example 43" $dir/newhist)
if [ $nr -ne 1 ]; then
    err "Contains: example 43" "1"
fi

if [ $BE -eq 0 ]; then
    exit # BE
fi

new "Kill backend"
# Check if premature kill
pid=`pgrep -u root -f clixon_backend`
if [ -z "$pid" ]; then
    err "backend already dead"
fi
# kill backend
stop_backend -f $cfg


rm -rf $dir
