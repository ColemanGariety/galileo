require "galileo/version"
require "octokit"
require "terminal-table/lib/terminal-table.rb"
require "time/time-ago-in-words"
require "colorize"
require "netrc"

class Galileo
  def initialize(query)
    repos = []
    n = Netrc.read
    
    unless n["api.github.com"]
      puts "" # \n
      login = [(print 'GitHub Username: '), $stdin.gets.rstrip][1]
      password = [(print 'GitHub Password: '), $stdin.gets.rstrip][1]
      n["api.github.com"] = login, password
      n.save
    end

    puts "" # \n
    puts "Searching the stars..."

    Octokit.configure do |client|
      client.netrc = true
      client.auto_paginate = true
    end

    Octokit.starred(Octokit.user.login).each do |repo|
      repos << [
                repo.name.yellow || '',
                repo.description || '',
                repo.language || '',
                repo.owner.login || '',
                repo.stargazers_count.to_s.blue || '0',
                Time.parse(repo.updated_at.to_s || '').time_ago_in_words
               ]
    end

    table = Terminal::Table.new
    table.headings = ['Name', 'Description', 'Language', 'Author', 'Stars', 'Last Updated']
    repos = repos.sort_by { |repo| -(repo[4].uncolorize.to_i) }.product([:separator]).flatten(1)[0...-1]
    table.rows = repos[0..20]
    table.style = { width: `/usr/bin/env tput cols`.to_i }

    puts "\n#{table}\n\n"
  end
end
