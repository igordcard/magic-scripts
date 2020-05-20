#!/bin/bash

filelist=$1

mkdir _root 2>/dev/null

while IFS= read -r filename
do
  dir=`dirname $filename`
  mkdir -p _root/$dir && cp -R $filename "$_"
  echo "$filename"
done < "$filelist"

