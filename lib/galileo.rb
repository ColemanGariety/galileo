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
    @query = query.join(' ')

    check_netrc

    @repos ||= repos

    puts "" # \n
    puts "Searching the stars..."
    construct_table
  end

  private

  def repos
    data = []

    Octokit.configure do |client|
      client.netrc = true
      client.auto_paginate = true
    end

    APICache.store = Moneta.new(:File, :dir => 'moneta')
    
    repos = APICache.get("starred", fail: [], timeout: 20, cache: 3600) do
      Octokit.starred(Octokit.user.login).each do |repo|
        data << [
         repo.name || '',
         repo.description || '',
         repo.language || '',
         repo.owner.login || '',
         repo.stargazers_count || '',
         repo.updated_at || ''
        ]
      end
      data
    end
    repos
  end

  def construct_table
    abort "\nNo results found. Have you starred any @repos? Have you exceeded your rate limit?\n\n" if @repos.empty?

    # Filter by the query
    @repos.select! do |repo|
      @query.downcase!
      repo[0].downcase.include?(@query) or
      repo[1].downcase.include?(@query)
    end

    # Sort by stars
    @repos.sort_by! { |repo| -repo[4] } if @query and @repos
    
    # Formatting
    @repos.map! do |repo|
      repo[0] = repo[0].yellow

      # Language color-coating
      case repo[2]
      when 'Clojur' then                         repo[2] = repo[2].colorize(:light_red)
      when 'Ruby' then                           repo[2] = repo[2].red
      when 'CSS', 'CoffeeScript', 'Python' then  repo[2] = repo[2].blue
      when 'Perl', 'Shell', 'Objective-C' then   repo[2] = repo[2].colorize(:light_blue)
      when 'PHP', 'C#' then                      repo[2] = repo[2].magenta
      when 'Emacs Lisp', 'C++' then              repo[2] = repo[2].colorize(:light_magenta)
      when 'Smalltalk' then                      repo[2] = repo[2].green
      when 'VimL', 'Scala' then                  repo[2] = repo[2].colorize(:light_green)
      when 'C' then                              repo[2] = repo[2].black
      when 'Go' then                             repo[2] = repo[2].yellow
      when 'Assembly', 'Java', 'JavaScript' then repo[2] = repo[2].colorize(:light_yellow)
      when 'Common Lisp' then                    repo[2] = repo[2].cyan
      end

      repo[4] = repo[4].to_s.blue
      repo[3] = repo[3].red
      repo[5] = repo[5].time_ago_in_words
      repo[6] = "github.com/#{repo[3]}/#{repo[0]}"
      repo
    end

    # Add separators
    @repos = @repos.product([:separator]).flatten(1)[0...-1]

    # Construct the table
    table = Terminal::Table.new
    table.headings = ['Name', 'Description', 'Language', 'Author', 'Stars', 'Last Updated', 'Link (⌘  + Click)']
    table.rows = @repos[0..20]
    table.style = { width: `/usr/bin/env tput cols`.to_i }

    # Print the table
    puts "\n#{table}\n\n"
  end

  def check_netrc
    config = Netrc.read
    unless config["api.github.com"]
      puts "" # \n
      login = [(print 'GitHub Username: '), $stdin.gets.rstrip][1]
      password = [(print 'GitHub Password: '), $stdin.gets.rstrip][1]
      config["api.github.com"] = login, password
      config.save
    end
  end
end
