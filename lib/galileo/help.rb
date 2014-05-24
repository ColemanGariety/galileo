# encoding: utf-8

class Galileo

  HELP = <<-EOS

  Usage (Init Github Account & See you most GitHub Stars):
    $ galileo

  Options:
    -r Refresh the repo cache from GitHub
    -l Filter by language

  Usage:
    $ galileo -r
    $ galileo -l [LANGUAGE]

  Search through the names & descriptions of the starred repos:
    $ galileo [KEYWORD]

  Filter by language:
    $ galileo [KEYWORD] -l [LANGUAGE]

  EOS

end
