#!/bin/bash
# META =========================================================================
# Title: wiki-parse.sh
# Usage: wiki-parse.sh 
# Description: Parse wikipedia page 
# Author: Colin Shea
# Created: 2016-05-22

# TODO

scriptname=$(basename $0)
function usage {
  echo "Usage: $scriptname"
  echo "Parse wikipedia infobox and return info."
  echo "  -i, --list          list of wiki pages"
  echo "  -h, --help          display help"
}

# set input values from command line arguments 
while [[ $# > 0 ]]; do
  arg="$1"
  case $arg in
    -i|--list)         shift; LIST="$1" ;;
    -h|--help)         usage; exit ;;        # print help
#    *) PAGE="$1" ;; 
  esac
  shift
done

# define file input/output
ROOTDIR="$(dirname $0)"

# define input
if [[ ! -z "${LIST}" ]]; then
  pages="${LIST}"
#  mapfile -t pages < "${LIST}"
else
  echo "Error: No input pages. Exiting."
  exit
fi


mapfile -t infobox_starts < <(
  grep -nm 1 -e '<table class="infobox vcard plainlist"' \
             -e '<table class="infobox biography vcard"' \
  $(cat "${pages}") | \
  cut -f 1,2 -d ':' )

mapfile -t infobox_ends < <(
  grep -n '</table>' \
  $(cat "${pages}") | \
  cut -f 1,2 -d ':' )

# split into page:line
# use page as key
# use line as value
declare -A starts 
for val in "${infobox_starts[@]}"; do
  starts["${val%%:*}"]="${val##*:}"
done

declare -A ends 
# save first end line that is > start line
for val in "${infobox_ends[@]}"; do 
  page="${val%%:*}"
  line="${val##*:}"
  if [[ "${ends["${page}"]}" == "" && ${line} -gt ${starts["${page}"]} ]]; then
    ends["${page}"]=${line}
  fi
done


for page in "${!ends[@]}"; do
  printf '%s\n' "${page}"

  head_line=$(( ends["${page}"] - 1 ))
  tail_line=$(( ends["${page}"] - starts["${page}"] ))

  mapfile -t infobox_content < <( 
    head -${head_line} "${page}" | \
    tail -${tail_line} | \
    sed -e 's,<th scope="row">,CATEGORY,g' \
        -e 's,<[^>]*>,,g' \
        -e 's,\[[^\]]*\],,g' \
        -e 's,&#160;, ,g' | \
    sed '/^$/d' )

#   printf '%s\n' "${infobox_content[@]}"
  declare -A category_limits
  category=""
  for line in "${!infobox_content[@]}"; do 
    case "${infobox_content[$line]}" in
      CATEGORY*)
        [[ ! -z "${category}" ]] && category_limits["${category}"]+=",${line}"
        category="${infobox_content[$line]#CATEGORY}"
        infobox_content[$line]="${category}"
        category_limits["${category}"]="${line}" ;;
    esac
  done
  [[ ! -z "${category}" ]] && category_limits["${category}"]+=",${#infobox_content[@]}"
  for category in "${!category_limits[@]}"; do 
    start="${category_limits[${category}]%%,*}"
    end="${category_limits[${category}]##*,}"
    printf '%s' "${category}"
    printf ', %s' "${infobox_content[@]:$((start + 1)):$((end - start - 1))}"
    printf '\n'
  done
  unset category_limits
done

# scratch ======================================================================

#  # parse page for background information (infobox)
#  infobox_start=""
#  infobox_end=""
#  infobox_start=$( 
#    < "${page}" \
#    grep -nm 1 -e '<table class="infobox vcard plainlist"'
#               -e '<table class="infobox biography vcard"' | \
#    cut -f 1 -d ':' )
#  [[ -z "${infobox_start}" ]] && continue
#  
#
#  mapfile -t table_ends < <( grep -n '</table>' "${page}" | \
#                             cut -f 1 -d ':' )
#  for end in "${table_ends[@]}"; do 
#    [[ $end -gt $infobox_start ]] && infobox_end=$end && break
#  done
#  [[ -z "${infobox_end}"   ]] && continue 

#  head_line=$(( infobox_end - 1 ))
#  tail_line=$(( infobox_end - infobox_start ))

#  mapfile -t infobox_content < <( head -${head_line} ${page} | \
#                                  tail -${tail_line} | \
#                                  sed 's,<[^>]*>,,g;s,\[[^\]]*\],,g' | \
#                                  sed '/^$/d' )
# parse infobox for genres
#  genre_start=""
#  genre_end=""
#  for line in "${!infobox_content[@]}"; do 
#    case "${infobox_content[$line]}" in 
#      'Genres')       
#        genre_start=${line}; continue;;
#      'Years active'|'Occupation(s)'|'Instruments'|'Website'|'Labels') 
#        [[ -z "${genre_start}" ]] && continue;
#        genre_end=${line};   break;;
#    esac
#  done
#  if [[ ! -z "${genre_start}" && ! -z "${genre_end}" ]]; then
#    printf ', %s' "${infobox_content[@]:$((genre_start + 1)):$((genre_end - genre_start - 1))}"
#  fi
