#!/bin/bash
# META =========================================================================
# Title: get-wiki.sh
# Usage: get-wiki.sh -i subject_list
# Description: Download first wikipedia page for each subject in list
# Author: Colin Shea
# Created: 2016-05-18

# TODO
# get html 

scriptname=$(basename $0)
function usage {
  echo "Usage: $scriptname"
  echo "Download first wikipedia page for subject (or list of subjects)."
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
ROOTDIR="/cygdrive/c/Users/sheacd/temp/genres"
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
DELAY=2

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

}

# get max user length for string padding format
max_len=0
for string in "${subjects[@]}"; do
  if [[ ${#string} -gt $max_len ]]; then
    max_len=${#string}
  fi
done

for subject in "${subjects[0]}"; do

  # encode string for url
  [[ ! -z "${topic}" ]] && subject+=" ${topic}"
  raw_url_encode "${subject}"
  wiki_search_params["search"]="${url_enc_string}"

#  printf '%-*s %s\n' ${max_len} "${subject}" "${url_enc_string}"
#  printf '%-*s' ${max_len} "${subject}"
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
  printf '%s\n' "${url_suffix}"

  # curl wiki search
  subject_html="${ROOTDIR}/html/wiki/${subject}.html"
  if [[ ! -f "${subject_html}" ]]; then
    sleep "${DELAY}"
    curl --silent "${url}" > "${subject_html}"
  fi

  # parse html for search results 
    # get line num at start of search results
  search_results_start=$( grep -xnm 1 "<ul class='mw-search-results'>" "${subject_html}" )
  search_results_end=$( grep -nm 1 '^<div class="visualClear">' "${subject_html}" )
    # map to array

  
  <li>
  <div class='mw-search-result-heading'>
  <a href="/wiki/10_Years_(band)" title="10 Years (band)" data-serp-pos="1">
  10 Years (band)
  </a>    
  </div> 
  <div class='searchresult'>
  10 Years are an American rock band, formed in Knoxville, Tennessee in 1999. The band consists of Jesse Hasek (lead vocals), Ryan Johnson (guitar, backing
  </div>
  <div class='mw-search-result-data'>
  18 KB (1,826 words) - 22:52, 3 May 2016
  </div>
  </li>

  # ' class="searchmatch"'
  # '<span>'
  # '</span>'

  # save html of search result
  
done

# scratch ======================================================================
