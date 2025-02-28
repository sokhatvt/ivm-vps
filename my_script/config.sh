#!/bin/bash

url=$(<url_repo)
cd ..

git config user.name "sokhatvt"
git config user.email "sokhatvt@gmail.com"
git remote add origin "$url"

read -p "Press enter to exit"