# global functions

logrotate() {
    [ -e "$LOG" ] || return 0
    log_size=`stat --format="%s" "$LOG"`

    if [ $log_size -gt $((100*1024)) ]
    then
        mv "$LOG" "$LOG".old
    fi
}

log() {
    echo "$(date --rfc-3339=seconds): $*"
}

save_variables() {
    set | grep ^$SAVE_VARIABLE_PREFIX
}

show_variables() {
    save_variables | while read line; do
      echo $1 $line
    done
}

count_error_lines() {
    first_grep_string="$@"
    count=0
    # use fifo so we don't have to use a subshell
    fifo=/tmp/errorlines.fifo
    mkfifo $fifo
    exec 3<> $fifo
    # limit to 100 lines we search string
    # reverse it since "read" reads from top to bottom but we want to count from bottom to top
    tail -n 100 "$LOG" | grep "$first_grep_string" | tac > $fifo
    while read -u3 -t1 line
    do
        # break if we don't find pattern
        echo "$line" | grep -qE 'ERROR$' && let count++ || break
    done < $fifo
    # cleanup
    exec 3>&-
    rm $fifo
    echo  $cnt
}
