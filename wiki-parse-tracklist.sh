#!/bin/bash
# META =========================================================================
# Title: wiki-parse-tracklist.sh
# Usage: wiki-parse-tracklist.sh -i file
# Description: Parse wikipedia pages for tracklist
# Author: Colin Shea
# Created: 2016-06-05

# TODO:
#   trim leading whitespace, trailing ','
#   option to set output delimiter (not ',')

# DONE

scriptname=$(basename $0)
function usage {
  echo "Usage: $scriptname"
  echo "Parse HTML tables from wikipedia to delimited text files."
  echo ""
  echo "  -i, --list      list of wiki pages"
  echo "  -h, --help      display help"
}

# set input values from command line arguments 
while [[ $# > 0 ]]; do
  arg="$1"
  case $arg in
    -i|--list)  LIST="$2"; shift ;; # input file
    -h|--help)  usage;      exit ;; # print help
    *) echo "Unknown option: $1" ;; # unknown option
  esac
  shift
done

# check input
[[   -z "${LIST}" ]] && echo "Error: No input specified."  && exit
[[ ! -f "${LIST}" ]] && echo "Error: Input is not a file." && exit
pages="${LIST}"

# print lines between patterns
#awk '/<table class="wikitable/{flag=1;next}/</table>/{flag=0}flag' \
awk '/<table class="tracklist"/,/<\/table>/;
     /class="firstHeading"/' \
     $( cat "${pages}" ) | \
tr '\n' ' ' | \
sed -e 's,</\(table\|tr\|h[0-9]\)>,\n,g' \
    -e 's,</t[dh]>,\,,g' \
    -e 's,<[^>]*>,,g'    \
    -e 's,\[[^]]*\],,g' \
    -e 's,\&#160;, ,g'   \
    -e 's,\&amp;,\&,g'