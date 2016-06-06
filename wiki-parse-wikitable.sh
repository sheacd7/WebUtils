#!/bin/bash
# META =========================================================================
# Title: wiki-parse-wikitable.sh
# Usage: wiki-parse-wikitable.sh -i file
# Description: Parse wikipedia pages for wikitables
# Author: Colin Shea
# Created: 2015-06-01

# TODO:
#   flatten li elements inside rows
#     compile set of labels from \s\w:\s
#     convert to table column headings and entries
#   flatten sub-headings in column labels
#     colspan, rowspan
#     scope
#   trim leading whitespace, trailing ','
#   option to set output delimiter (not ',')

# DONE
#   keep 'class="firstHeading"'
#   keep 'class="mw-headline"'
#   remove '[]' refs
#   replace most of code with awk script to match lines between patterns
# x add input option to specify list of input pages
# x match open/close tags with grep -A1 on open tags
# x match tag line numbers to files using grep output
# x extract each table to array using -s seek and -n length
# x use filename from input for default output name
# x tee output to stdout and file

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
awk '/<table class="wikitable/,/<\/table>/;
     /class="firstHeading"/;
     /class="mw-headline"/' \
     $( cat "${pages}" ) | \
tr '\n' ' ' | \
sed -e 's,</\(table\|tr\|h[0-9]\)>,\n,g' \
    -e 's,</t[dh]>,\,,g' \
    -e 's,<[^>]*>,,g'    \
    -e 's,\[[^]]*\],,g' \
    -e 's,\&#160;, ,g'   \
    -e 's,\&amp;,\&,g'

#     -e 's,</tr>,\n,g'    \

#table_open='<table class="wikitable'
#table_close='</table>'
#
## build array of matched table tag pairs
##   file : line number of open tag : open tag
##   file : line number of close tag : close tag
#mapfile -t table_lines < <( \
#  grep -Fon -e "${table_open}" \
#            -e "${table_close}" \
#        $( printf '%q\n' "${in_files[@]}" ) | \
#  grep -FA 1 "${table_open}" | \
#  sed '/^--$/d' )
#
#declare -a filenames
#filenames=(   "${table_lines[@]%%:*}")
#table_lines=( "${table_lines[@]%:*}" )
#table_lines=( "${table_lines[@]#*:}" )
#
#
#
## for each table
#for ((idx=0; i<"${#table_lines[@]}"; i+=2)); do
#
#  # extract table from opening to closing tags
#  start="${table_lines[idx]}"
#  end="${table_lines[idx+1]}"
#  len=$(( end - start - 1 ))
#  mapfile -t -s ${start} -n ${len} table < "${filenames[idx]}"
#
#  printf '%s\n' "${table[*]}"
#
#  # for each table
#  # replace /td and /th with ','
#  # replace /tr with '\n'
#  # remove html markup
#done  | \
#  sed -e 's,</tr>,\n,g' \
#      -e 's,</t[dh]>,\,,g' \
#      -e 's,<[^>]*>,,g' \
#      -e 's,&#160;?,,g' | \
#  sed '/^$/d' > "${out_file}"
#  | \
#  tee "${out_file}"

# scratch ======================================================================
# wikitable types
#   "" [sortable]
#   plainrowheaders [sortable]

# print lines between patterns
# awk '/p1/{flag=1;next}/p2/{flag=0}flag'
# print lines including patterns
# awk '/p1/,/p2/' 

# sed -n '${start},${end}p' "${filename}"

# skip table lines that are not openings
#  [[ "${table_lines[$idx]##*:}" != "${table_open}" ]] && continue

#  start="${table_lines[idx]%:*}"
#  start="${start#*:}"
#  end="${table_lines[idx+1]%:*}"
#  end="${end#*:}"

#  table="${content[@]:$start:$len}"