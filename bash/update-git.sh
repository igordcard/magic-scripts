#!/bin/bash

find . -name .git -type d -exec bash -c "cd \"{}\"/../ ; pwd ; git pull" \;
