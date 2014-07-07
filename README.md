resque-example
==============

To launch worker:

bundle exec rake resque:work QUEUE=* TERM_CHILD=1 RESQUE_TERM_TIMEOUT=10 VVERBOSE=1
