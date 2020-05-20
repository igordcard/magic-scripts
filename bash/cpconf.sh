#!/bin/bash

operation=$1
filelist=$2
realroot=$3


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
  tar -xf $filelist
  #cp -R --no-preserve=mode,ownership _root/* $realroot
  #rsync -rltDv  _root/ $realroot/
  rm -rf _root
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
	  echo "       cpconf restore <backup archive> <destination root dir>"
    ;;
esac
