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
require 'command_line_reporter'

class Table
  include CommandLineReporter

  def initialize(repos)
    table(:border => true) do
      row do
       column('Name', :width => 20)
       column('Description', :width => 30, :align => 'right', :padding => 5)
       column('Language', :width => 15)
       column('Author', :width => 15)
       column('Stars', :width => 15)
       column('Last Updated', :width => 15)
       column(ENV['_system_name'] == 'OSX' ? 'Link (⌘  + Click)' : 'Link', :width => 20)
     end
      repos.each do |repo|
        row do
          repo.each do |data|
            column(data)
          end
        end
      end
   end
  end
end

class Galileo
  def initialize(query)
    repos = []
    config = Netrc.read
    
    unless config["api.github.com"]
      puts # \n
      login = [(print 'GitHub Username: '), STDIN.gets.rstrip][1]
      password = [(print 'GitHub Password: '), STDIN.noecho(&:gets).rstrip][1]
      puts # \n
      config["api.github.com"] = login, password
      config.save
    end

    client = Octokit::Client.new netrc: true, auto_paginate: true

    # 2FA (help?)
    # user = begin
    #          client.user
    #        rescue Octokit::OneTimePasswordRequired
    #          otp = [(print 'OTP: '), STDIN.noecho(&:gets).rstrip][1]
    #          client.create_authorization scopes: ['user'], headers: { 'X-GitHub-OTP' => otp }
    #        end

    APICache.store = Moneta.new(:File, dir: Dir.tmpdir)

    repos = APICache.get("starred", fail: [], timeout: 20, cache: 3600) do
      repos = []

      puts # \n
      puts "Searching the stars..."

      # GET
      client.starred.concat(client.repos).each do |repo|
        repos << [
         repo.name || '',
         repo.description || '',
         repo.language || '',
         repo.owner.login || '',
         repo.stargazers_count || '',
         repo.updated_at || ''
        ]
      end

      repos.uniq
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
          when 'Clojur'                         then repo[2] = repo[2].colorize(:light_red)
          when 'Ruby'                           then repo[2] = repo[2].red
          when 'CSS', 'CoffeeScript', 'Python'  then repo[2] = repo[2].blue
          when 'Perl', 'Shell', 'Objective-C'   then repo[2] = repo[2].colorize(:light_blue)
          when 'PHP', 'C#'                      then repo[2] = repo[2].magenta
          when 'Emacs Lisp', 'C++'              then repo[2] = repo[2].colorize(:light_magenta)
          when 'Smalltalk', 'TeX'               then repo[2] = repo[2].green
          when 'VimL', 'Scala'                  then repo[2] = repo[2].colorize(:light_green)
          when 'C'                              then repo[2] = repo[2].black
          when 'Go'                             then repo[2] = repo[2].yellow
          when 'Assembly', 'Java', 'JavaScript' then repo[2] = repo[2].colorize(:light_yellow)
          when 'Common Lisp'                    then repo[2] = repo[2].cyan
          end

          repo[4] = repo[4].to_s.blue
          repo[3] = repo[3].red
          repo[5] = repo[5].time_ago_in_words
          repo[6] = "github.com/#{repo[3].uncolorize}/#{repo[0].uncolorize}".magenta
          repo
        end

        Table.new(repos[0..20])

        # Add separators
        repos = repos.product([:separator]).flatten(1)[0...-1]

        # Construct the table
        table = Terminal::Table.new
        table.headings = ['Name', 'Description', 'Language', 'Author', 'Stars', 'Last Updated', ENV['_system_name'] == 'OSX' ? 'Link (⌘  + Click)' : 'Link']
        table.rows = repos[0..20]
        table.style = { width: `/usr/bin/env tput cols`.to_i }

        # Print the table
        # puts "\n#{table}\n\n"
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
