#!/bin/bash

operation=$1
filelist=$2


backup() {
  mkdir _root 2>/dev/null

  while IFS= read -r filename
  do
    dir=`dirname "$filename"`
    mkdir -p "_root$dir"
    cp -pR ${filename} "$_"
    echo "$filename"
  done < "$filelist"
}


restore() {
  pwd
}

case $operation in
  backup )
	  echo Backing up...
	  backup
    ;;
  restore )
	  echo Restoring...
	  restore
    ;;
  * )
	  echo "Usage: cpconf backup <file with filelist>"
	  echo "       cpconf restore <backup root dir> <true root dir>"
    ;;
esac
