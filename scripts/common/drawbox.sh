#!/bin/false

function box_out()
{
  # split input
  lines=()
  readarray -t lines <<< "$@"

  # border character
  c='#'
  
  pad=0
  # get length of longest line, required for padding
  for i in "${lines[@]}"; do
      ((${#i} > pad)) &&
      pad=${#i}
  done
  
  # make a string to fill top/bottom
  fill=$(printf %$((pad + 4))s "$c")
  fill=${fill// /$c}
  
  # print the text box
  printf '%s\n' "$fill"
  
  for line in "${lines[@]}"; do
      printf "$c %-${pad}s $c\n" "$line"
  done
  
  printf '%s\n' "$fill"
}
