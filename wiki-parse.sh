#!/bin/bash
# META =========================================================================
# Title: wiki-parse.sh
# Usage: wiki-parse.sh 
# Description: Parse wikipedia page 
# Author: Colin Shea
# Created: 2016-05-22

# TODO
# if genre not found,
#   find disambiguation link if it exists (~67)
# 


scriptname=$(basename $0)
function usage {
  echo "Usage: $scriptname"
  echo "Parse wikipedia ."
  echo "  -i, --list          list of wiki pages"
  echo "  -d, --disambiguate  additional term for all subjects"
  echo "  -h, --help          display help"
}

# set input values from command line arguments 
while [[ $# > 0 ]]; do
  arg="$1"
  case $arg in
    -i|--list)         shift; LIST="$1" ;;
    -d|--disambiguate) shift; DISAM="$1" ;;
    -h|--help)         usage; exit ;;        # print help
    *) PAGE="$1" ;; 
  esac
  shift
done

# define file input/output
#ROOTDIR="/cygdrive/c/Users/sheacd/GitHub/WebUtils"
ROOTDIR="$(dirname $0)"
#printf '%s\n' "${ROOTDIR}"
topic=""

# # define input
if [[ ! -z "${PAGE}" ]]; then 
  pages[0]="${PAGE}"
elif [[ ! -z "${LIST}" ]]; then
  mapfile -t pages < "${LIST}"
else
  echo "Error: No input pages. Exiting."
  exit
fi
# if [[ ! -z "${DISAM}" ]]; then
#   topic="${DISAM}"
# fi
# 
# # params
# DELAY=5

for page in "${pages[@]}"; do

  printf '\n%s' "${page}"

  # parse page for background information (infobox)
  infobox_start=""
  infobox_end=""
  infobox_start=$( grep -nm 1 '<table class="infobox vcard plainlist"' "${page}" | \
                   cut -f 1 -d ':' )
  if [[ -z "${infobox_start}" ]]; then
    infobox_start=$( grep -nm 1 '<table class="infobox biography vcard"' "${page}" | \
                     cut -f 1 -d ':' )
    [[ -z "${infobox_start}" ]] && continue
  fi

  mapfile -t table_ends < <( grep -n '</table>' "${page}" | \
                             cut -f 1 -d ':' )
  for end in "${table_ends[@]}"; do 
    [[ $end -gt $infobox_start ]] && infobox_end=$end && break
  done
  [[ -z "${infobox_end}"   ]] && continue 

  head_line=$(( infobox_end - 1 ))
  tail_line=$(( infobox_end - infobox_start ))

  mapfile -t infobox_content < <( head -${head_line} ${page} | \
                                  tail -${tail_line} | \
                                  sed 's,<[^>]*>,,g;s,\[[^\]]*\],,g' | \
                                  sed '/^$/d' )

  # parse infobox for genres
  genre_start=""
  genre_end=""
  for line in "${!infobox_content[@]}"; do 
    case "${infobox_content[$line]}" in 
      'Genres')       
        genre_start=${line}; continue;;
      'Years active'|'Occupation(s)'|'Instruments'|'Website'|'Labels') 
        [[ -z "${genre_start}" ]] && continue;
        genre_end=${line};   break;;
    esac
  done
  if [[ ! -z "${genre_start}" && ! -z "${genre_end}" ]]; then
    printf ', %s' "${infobox_content[@]:$((genre_start + 1)):$((genre_end - genre_start - 1))}"
  fi
done

# scratch ======================================================================

# function raw_url_encode() {
#   local string="${1}"
#   local strlen=${#string}
#   local encoded=""
#   local pos c o
# 
#   for (( pos=0 ; pos<strlen ; pos++ )); do
#      c=${string:$pos:1}
#      case "$c" in
#         [-_.~a-zA-Z0-9] ) o="${c}" ;;
#         * ) printf -v o '%%%02x' "'$c" ;;
#      esac
#      encoded+="${o}"
#   done
#   url_enc_string="${encoded}"
# }
# 
# function raw_url_decode() {
#   # replace hex chars with ascii equivalents
#   printf -v url_dec_string '%b' "${1//%/\\x}"
# }
