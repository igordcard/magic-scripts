#!/bin/bash

operation=$1
filelist=$2


backup() {
  mkdir _root 2>/dev/null

  while IFS= read -r filename
  do
    [[ "$filename" =~ ^[[:space:]]*# ]] && continue
    dir=`dirname "$filename"`
    mkdir -p "_root$dir"
    cp -pR ${filename} "$_"
    echo "$filename"
  done < "$filelist"
  archive=$filelist-$(date +%s).tar.gz
  echo "Archiving to $archive..."
  tar -czf $archive _root
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
