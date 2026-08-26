#!/usr/bin/env bash

awk '
/MemTotal:/ {total=$2}
/MemAvailable:/ {avail=$2}
END {
    if (total > 0) {
        used=(total-avail)/1048576
        printf "%.1fG", used
    } else {
        printf "N/A"
    }
}' /proc/meminfo
