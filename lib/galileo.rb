require "galileo/version"
require "octokit"
require "terminal-table"
require "time"
require "time/time_ago_in_words"
require "colorize"

class Galileo
  def initialize(query)
    repos = []

    user = Octokit.user 'JacksonGariety'
    user.rels[:starred].get.data.each do |repo|
      repos << [
                repo.name.yellow,
                repo.description,
                repo.language,
                repo.owner.login,
                repo.stargazers_count.to_s.blue,
                Time.parse(repo.updated_at.to_s).time_ago_in_words
               ]
    end

    table = Terminal::Table.new
    table.headings = ['Name', 'Description', 'Language', 'Author', 'Stars', 'Last Updated']
    table.rows = repos[0..20]    
    table.style = { :width => `/usr/bin/env tput cols`.to_i }

    puts "\n#{table}\n\n"
  end
end
