#!/bin/bash

# this is where you do your install logic
sudo apt install nodejs npm

# these lines are a must-have. without it, initra doesnt know
# if the installation is done and if it should close the connection.
echo "initra://install/done"
echo "initra://ssh/close"