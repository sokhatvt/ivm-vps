#!/bin/bash

cd ..
git add *
git commit -m "Beta project"
git push -u -f origin master

read -p "Press enter to exit"