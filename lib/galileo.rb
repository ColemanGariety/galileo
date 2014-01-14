require "galileo/version"
require "octokit"
require "terminal-table/lib/terminal-table.rb"
require "time/time-ago-in-words"
require "colorize"
require "netrc"
require "httparty"
require "api_cache"
require "moneta"

class Galileo
  def initialize(query)
    repos = []
    config = Netrc.read
    
    unless config["api.github.com"]
      puts "" # \n
      login = [(print 'GitHub Username: '), $stdin.gets.rstrip][1]
      password = [(print 'GitHub Password: '), $stdin.gets.rstrip][1]
      config["api.github.com"] = login, password
      config.save
    end

    Octokit.configure do |client|
      client.netrc = true
      client.auto_paginate = true
    end

    APICache.store = Moneta.new(:File, :dir => 'moneta')

    repos = APICache.get("starred", fail: [], timeout: 20, cache: 3600) do
      repos = []

      puts "" # \n
      puts "Searching the stars..."

      # GET
      Octokit.starred(Octokit.user.login).each do |repo|
        repos << [
         repo.name || '',
         repo.description || '',
         repo.language || '',
         repo.owner.login || '',
         repo.stargazers_count || 0,
         repo.updated_at
        ]
      end      

      repos
    end

    if repos.any?
      if query
        # Filter by the query
        repos.select! do |repo|
          query.downcase!
          repo[0].downcase.include?(query) or
          repo[1].downcase.include?(query)
        end

        # Sort by stars
        repos.sort_by! { |repo| -repo[4] } if query and repos
      end

      if repos.any?
        # Formatting
        repos.map! do |repo|
          repo[0] = repo[0].yellow
          repo[4] = repo[4].to_s.blue
          repo[5] = repo[5].time_ago_in_words
          repo[6] = "github.com/#{repo[3]}/#{repo[0]}"
          repo
        end

        # Add separators
        repos = repos.product([:separator]).flatten(1)[0...-1]

        # Construct the table
        table = Terminal::Table.new
        table.headings = ['Name', 'Description', 'Language', 'Author', 'Stars', 'Last Updated', 'Link (⌘  + Click)']
        table.rows = repos[0..20]
        table.style = { width: `/usr/bin/env tput cols`.to_i }

        # Print the table
        puts "\n#{table}\n\n"
      else
        puts "\nNo results for that query.\n\n"
      end
    else
      puts "\nNo results found. Have you starred any repos? Have you exceeded your rate limit?\n\n"
    end    
  end
end
