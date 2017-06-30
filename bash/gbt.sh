#!/bin/bash
# gbt (gerrit backup tool)
# igordcard - 20160313

patch=$1
revision=1

mkdir $patch
mkdir $patch/commits
mkdir $patch/comments
mkdir $patch/patches
cd $patch

# get global patch information/comments
wget https://review.openstack.org/changes/$patch/detail?O=404 -O $patch.json 2>/dev/null

while :; do
    # get diff file for patch set (revision)
    wget=`wget https://review.openstack.org/changes/$patch/revisions/$revision/patch?zip --content-disposition 2>&1`
    stat=$?

    # quit if the patch set does not exist
    if [[ $stat -gt 0 ]]; then
        exit
    fi

	# deal with the naming of patch set files that will be saved
    file=`echo $wget | grep -E -o ‘.+’`
    file=${file:1:8}
	newname=$(printf %03d $revision)-$file

	# get the patch file to the proper folder
    mv $file.diff.zip patches/$newname.diff.zip

	# get comments for the files in this patch set
	wget https://review.openstack.org/changes/$patch/revisions/$revision/comments -O comments/$newname-comments.json 2>/dev/null

	# get commit info for this patch set
	wget https://review.openstack.org/changes/$patch/revisions/$revision/commit -O commits/$newname-commit.json 2>/dev/null

	echo "Patch Set $newname downloaded!"

	# prepare for next patch set
    revision=$((revision+1))
done

