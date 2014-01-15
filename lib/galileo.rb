require "galileo/version"
require "octokit"
require "terminal-table/lib/terminal-table.rb"
require "time/time-ago-in-words"
require "colorize"
require "netrc"
require "api_cache"
require "moneta"
require "tmpdir"
require "io/console"

class Galileo
  def initialize(query)
    repos = []
    config = Netrc.read
    
    unless config["api.github.com"]
      puts "" # \n
      login = [(print 'GitHub Username: '), STDIN.gets.rstrip][1]
      password = [(print 'GitHub Password: '), STDIN.noecho(&:gets).rstrip][1]
      config["api.github.com"] = login, password
      config.save
    end

    Octokit.configure do |client|
      client.netrc = true
      client.auto_paginate = true
    end

    APICache.store = Moneta.new(:File, dir: Dir.tmpdir)

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
         repo.stargazers_count || '',
         repo.updated_at || ''
        ]
      end      

      repos
    end

    if repos.any?
      if query.any?
        languages = []

        # If the language parameter if present
        if query.index('-l')
          languages = query.delete(query[query.index('-l') + 1]).split(',')
          query.delete('-l')
        end

        # Filter by the query
        repos.select! do |repo|
          

          # Join the arguments into a query
          q = query.join(' ').downcase
          repo[0].downcase.include?(q) or
          repo[1].downcase.include?(q)
        end

        # Sort by stars
        repos.sort_by! { |repo| -repo[4] } if query and repos.any?

        # If languages
        if languages.any?
          languages.map!(&:downcase)
          
          repos.select! do |repo|
            languages.include? repo[2].downcase
          end
        end
      end

      if repos.any?
        # Formatting
        repos.map! do |repo|
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
          repo[6] = "github.com/#{repo[3].uncolorize}/#{repo[0].uncolorize}".magenta
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

  def self.refresh
    FileUtils.rm_rf(Dir.tmpdir)
    self.new([])
  end
end
