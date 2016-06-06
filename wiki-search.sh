#!/bin/bash
# META =========================================================================
# Title: wiki-search.sh
# Usage: wiki-search.sh -i subject_list -d disambiguate_term
# Description: Search wikipedia for subjects with optional disambiguation terms
# Author: Colin Shea
# Created: 2016-05-18

# TODO
# "lucky" option - emit href to first search result if no match
# fuzzy match non-ASCII characters


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
ROOTDIR="$(dirname $0)"

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
  disambig_file="${DISAM}"
  mapfile -t disambiguators < "${disambig_file}"
  disambiguators=( "${disambiguators[@]//\"/}" )
fi

# script curl parameters
DELAY=5



function set_wiki_search_url() {
  search_query="${1}"

  # wikipedia search url parameters
  wiki_search_base_url="https://en.wikipedia.org/w/index.php?"
  declare -A wiki_search_params
  wiki_search_params["search"]=""
  wiki_search_params["title"]="Special%3ASearch"
  wiki_search_params["fulltext"]="Search"

  # encode string for url
  raw_url_encode "${search_query}"
  wiki_search_params["search"]="${url_enc_string}"

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
  wiki_search_url="${wiki_search_base_url}${url_suffix}"
}

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

function string_match() {
  # try to match string to target with heuristic substitutions
  local target="${1}"
  local string="${2}"
  match_result="True"
  # try exact literal match
  [[ "${target}" == "${string}" ]] && return
  # try canonical capitalization
  target="${target// And / and }"
  target="${target// For / for }"
  target="${target// The / the }"
  [[ "${target}" == "${string}" ]] && return
  # try and | &
  [[ "${target// and / & }" == "${string}" ]] && return
  [[ "${target// & / and }" == "${string}" ]] && return
  # try leading "The "
  target2="${target#The }"
  [[ "${target2}" == "${string}" ]] && return
  target2="The ${target}"
  [[ "${target2}" == "${string}" ]] && return
  # last ditch, try trailing '.' for initialisms
  [[ "${target}." == "${string}" ]] && return
  
  match_result="False"
  return
}

function parse_wiki_search_page() {
  local page="${1}"

  # parse html for search results 
  mapfile -t search_results < <( \
    < "${subject_html}" \
    grep "class='mw-search-result-heading'" | \
    sed -e 's,</*li[^>]*>,,g' \
        -e 's,</*div[^>]*>,,g' \
        -e 's,</*span[^>]*>,,g' \
        -e 's,</*ul[^>]*>,,g' )

  # map search results to arrays
  local i=-1
  for result in "${search_results[@]}"; do
    : $(( i++ ))
    href="${result##*href=\"}"
    href="${href%%\"*}"
    title="${result##*title=\"}"
    title="${title%%\"*}"
    title="${title//&amp;/&}"
    preview="${result##*</a>}"

    hrefs[$i]="${href}"
    titles[$i]="${title}"
    previews[$i]="${preview}"
  done
}

function parse_wiki_disambiguation_page() {
  local page="${1}"

  # parse html for relevant disambiguation results
  mapfile -t disambiguation_results < <( \
    < "${page}" \
    sed 's,<[^a>]*>,,g;s,<div[^>]*>,,g' | \
#    grep -f "${disambig_file}" )
    grep -e "band" \
         -e "music group" \
         -e "rock group" \
         -e "musician" \
         -e "vocalist" \
         -e "singer" \
         -e "guitarist" )

  # map disambiguation results to arrays
  local i=-1
  for result in "${disambiguation_results[@]}"; do
    : $(( i++ ))
    href="${result##*href=\"}"
    href="${href%%\"*}"
    title="${result##*title=\"}"
    title="${title%%\"*}"
    title="${title//&amp;/&}"
    preview="${result##*</a>}"

    hrefs[$i]="${href}"
    titles[$i]="${title}"
    previews[$i]="${preview}"
  done

}


for subject in "${subjects[@]}"; do

  printf '%s\n' "${subject}"

  subject_disambig="${subject}"' (disambiguation)'
  # build url
  set_wiki_search_url "${subject_disambig}"
  # get page
  subject_html="${ROOTDIR}/html/wiki/search/${subject_disambig}.html"
  # curl wiki search url
  if [[ ! -f "${subject_html}" ]]; then
    sleep "${DELAY}"
    curl --silent "${wiki_search_url}" > "${subject_html}"
  fi

  # does (disambiguation) page exist
  disambig_line="$( \
    < "${subject_html}" \
    grep -om 1 -e 'href="[^"]*" title="[^"]*" class="mw-disambig"' \
               -e 'href="[^"]*" title="[^"]*" class="mw-redirect mw-disambig"' )"

  declare -a hrefs
  declare -a titles
  declare -a previews

  if [[ ! -z "${disambig_line}" ]]; then
    href="${disambig_line##*href=\"}"
    href="${href%%\"*}"
    title="${disambig_line##*title=\"}"
    title="${title%%\"*}"
    title="${title//&amp;/&}"

    # build url
    wiki_url="https://en.wikipedia.org${href}"
    # get page
    subject_html="${ROOTDIR}/html/wiki/${title}.html"
    # curl wiki search url
    if [[ ! -f "${subject_html}" ]]; then
      sleep "${DELAY}"
      curl --silent "${wiki_url}" > "${subject_html}"
    fi

    parse_wiki_disambiguation_page "${subject_html}"

    # output disambiguation results
    printf '%s\n' "${subject}" >> "${ROOTDIR}/disambiguations.txt"
    printf '%s\n' "${subject}" >> "${ROOTDIR}/disambiguation_results.txt"
    for pos in "${!hrefs[@]}"; do
      printf '%2s, %s, %s\n' "${pos}" "${hrefs[$pos]}" "${titles[$pos]}" >> "${ROOTDIR}/disambiguation_results.txt"
      # printf '%s\n' "${previews[$pos]}"
    done
  else
    set_wiki_search_url "${subject}"
    # get page
    subject_html="${ROOTDIR}/html/wiki/search/${subject}.html"
    # curl wiki search url
    if [[ ! -f "${subject_html}" ]]; then
      sleep "${DELAY}"
      curl --silent "${url}" > "${subject_html}"
    fi
  
    parse_wiki_search_page "${subject_html}"

  fi

  # try to match subject to title
  match=""
  for pos in "${!hrefs[@]}"; do
    string_match "${subject}" "${titles[$pos]}"
    [[ "${match_result}" == "True" ]] && match="${pos}" && break
  done

  # if no match found, try disambiguators
  if [[ -z "${match}" && ! -z "${DISAM}" ]]; then
    for disambiguator in "${disambiguators[@]}"; do
      d_subject="${subject} (${disambiguator})"
      echo "${d_subject}"
      for pos in "${!hrefs[@]}"; do
        string_match "${d_subject}" "${titles[$pos]}"
        [[ "${match_result}" == "True" ]] && match="${pos}" && break
      done
      [[ ! -z "${match}" ]] && break
    done
  fi

  # output matches
  if [[ ! -z "${match}" ]]; then
    # match found
    if [[ "${subject}" == "${titles[$match]}" ]]; then
      printf '%s, %s\n' "${subject}" "${hrefs[$match]}" >> "${ROOTDIR}/matches_exact.txt"
    else
      printf '%s, %s, %s\n' "${subject}" "${titles[$match]}" "${hrefs[$match]}" >> "${ROOTDIR}/matches_fuzzy.txt"
    fi
  else
    # save first match to lucky results
    printf '%s, %s, %s\n' "${subject}" "${titles[0]}" "${hrefs[0]}" >> "${ROOTDIR}/matches_lucky.txt"
    # no match found, dump results
    printf '%s\n' "${subject}" >> "${ROOTDIR}/nonmatches.txt"
    printf '%s\n' "${subject}" >> "${ROOTDIR}/nonmatch_results.txt"
    for pos in "${!hrefs[@]}"; do
      printf '%2s, %s, %s\n' "${pos}" "${hrefs[$pos]}" "${titles[$pos]}" >> "${ROOTDIR}/nonmatch_results.txt"
      # printf '%s\n' "${previews[$pos]}"
    done
  fi

  unset hrefs
  unset titles
  unset previews

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

#  disambig_line="$( \
#    < "${subject_html}" \
#    sed 's,<[^>]*>,,g' | \
#    grep -n 'There is a page named "${subject} (disambiguation)" on Wikipedia' | \
#    cut -f 1 -d ':' )"
#    disambig_result="$( \
#      < "${subject_html}" \
#      head -${disambig_line} | \
#      tail -1 | \
#      sed -e 's,</*li[^>]*>,,g' \
#          -e 's,</*div[^>]*>,,g' \
#          -e 's,</*span[^>]*>,,g' \
#          -e 's,</*ul[^>]*>,,g' )"
