#!/usr/bin/env bash
bundle config --delete path
bundle config --delete disable_shared_gems
bundle config set --local path '~/.bundle'
bundle install
