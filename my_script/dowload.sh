#!/bin/bash

url=$(<url_repo)

git clone "$url"

read -p "Press enter to exit"