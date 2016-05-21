#!/bin/bash
# META =========================================================================
# Title: wiki-search.sh
# Usage: wiki-search.sh -i subject_list -d disambiguate_term
# Description: Search wikipedia for subjects with optional disambiguation terms
# Author: Colin Shea
# Created: 2016-05-18

# TODO
# format output from html
# "lucky" option - emit href to first search result

scriptname=$(basename $0)
function usage {
  echo "Usage: $scriptname"
  echo "Search wikipedia for subjects with optional disambiguation terms."
  echo "  -i, --list          list of subjects"
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
    *) SUBJECT="$1" ;; 
  esac
  shift
done

# define file input/output
#ROOTDIR="/cygdrive/c/Users/sheacd/GitHub/WebUtils"
ROOTDIR="$(dirname $0)"
#printf '%s\n' "${ROOTDIR}"
topic=""

# define input
if [[ ! -z "${SUBJECT}" ]]; then 
  subjects[0]="${SUBJECT}"
elif [[ ! -z "${LIST}" ]]; then
  mapfile -t subjects < "${LIST}"
else
  echo "Error: No input subjects. Exiting."
  exit
fi
if [[ ! -z "${DISAM}" ]]; then
  topic="${DISAM}"
fi

# params
DELAY=5

wiki_search_url="https://en.wikipedia.org/w/index.php?"
#wiki_search_string="booker+t.+%26+the+m.g.s+%28band%29"
declare -A wiki_search_params
wiki_search_params["search"]=""
wiki_search_params["title"]="Special%3ASearch"
wiki_search_params["fulltext"]="Search"


function raw_url_encode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * ) printf -v o '%%%02x' "'$c" ;;
     esac
     encoded+="${o}"
  done
  url_enc_string="${encoded}"
}

function raw_url_decode() {
  # replace hex chars with ascii equivalents
  printf -v url_dec_string '%b' "${1//%/\\x}"
}

function parse_wiki_search_results() {
  echo "Test"
}



for subject in "${subjects[@]}"; do

  # encode string for url
  [[ ! -z "${topic}" ]] && subject+=" ${topic}"
  raw_url_encode "${subject}"
  wiki_search_params["search"]="${url_enc_string}"

  printf '%s\n' "${subject}"

  # assemble URL
  url_suffix=""
  for param in "${!wiki_search_params[@]}"; do
    if [[ "${param}" != "" ]]; then
      url_suffix+="${param}"'='"${wiki_search_params[$param]}"'&'
    fi
  done
  url_suffix="${url_suffix/%&/}"
  # replace %20 (space) with '+'
  url_suffix="${url_suffix//%20/+}"
  url="${wiki_search_url}${url_suffix}"
#  printf '%s\n' "${url_suffix}"

  # curl wiki search
  subject_html="${ROOTDIR}/html/wiki/${subject}.html"
  if [[ ! -f "${subject_html}" ]]; then
    sleep "${DELAY}"
    curl --silent "${url}" > "${subject_html}"
  fi

  # parse html for search results 
  mapfile -t search_results < <( \
    < "${subject_html}" \
    grep "class='mw-search-result-heading'" | \
    sed -e 's,</*li[^>]*>,,g;s,</*div[^>]*>,,g;s,</*span[^>]*>,,g;s,</*ul[^>]*>,,g' )

  declare -a hrefs
  declare -a titles
  declare -a previews
  # map to array
  for result in "${search_results[@]}"; do
    pos="${result##*data-serp-pos=\"}"
    pos="${pos%%\"*}"
    href="${result##*href=\"}"
    href="${href%%\"*}"
    title="${result##*title=\"}"
    title="${title%%\"*}"
    preview="${result##*</a>}"

    hrefs[$pos]="${href}"
    titles[$pos]="${title}"
    previews[$pos]="${preview}"
  done
 
  for pos in "${!hrefs[@]}"; do
    printf '%2s, %s, %s\n' "${pos}" "${hrefs[$pos]}" "${titles[$pos]}" 
#    printf '%s\n' "${previews[$pos]}"
  done

  # save html of search result
  
done

# scratch ======================================================================

#  search_results_start=$( \
#    grep -xnm 1 "<ul class='mw-search-results'>" "${subject_html}" | \
#    cut -f 1 -d ':' )
#  search_results_end=$( \
#    grep -nm 1 '^<div class="visualClear">' "${subject_html}" | \
#    cut -f 1 -d ':' )
#  h_line=$(( search_results_end - 1 ))
#  t_line=$(( search_results_end - search_results_start ))

#    head -${h_line} | \
#    tail -${t_line} | \

    # search position as index
    # href link and title
    # preview text
#  mapfile -t hrefs < <( \
#    printf '%s\n' "${search_results[@]}" | \
#    grep -Eo 'href="[^"]*"' | \
#    sed 's,href=,,g' )
#  mapfile -t titles < <( \
#    printf '%s\n' "${search_results[@]}" | \
#    grep -Eo 'title="[^"]*"' | \
#    sed 's,title=,,g' )
#  mapfile -t indices < <( \
#    printf '%s\n' "${search_results[@]}" | \
#    grep -Eo 'data-serp-pos="[^"]*"' | \
#    sed 's,data-serp-pos=,,g' )  