#!/bin/bash

cd `dirname $0`
ansible-galaxy install -r requirements.yml -p roles/

