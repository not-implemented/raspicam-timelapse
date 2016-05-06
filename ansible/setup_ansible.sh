#!/bin/bash

cd `dirname $0`
ansible-galaxy install -r requirements.txt -p roles/

