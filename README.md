RuboCop Regression Test
====

[![CircleCI](https://circleci.com/gh/pocke/rubocop-regression-test.svg?style=svg)](https://circleci.com/gh/pocke/rubocop-regression-test)


Usage
---

```bash
# Install the latest RuboCop
$ git clone https://github.com/rubocop-hq/rubocop
$ cd rubocop
$ bundle install
$ bundle exec rake install

$ cd /path/to/pocke/rubocop-regression-test

# Run on specified repo, all configuration conbinations
$ ruby main.rb check owner/repo
```
