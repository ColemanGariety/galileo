class Time
  module Units
    Second     = 1
    Minute     = Second  * 60
    Hour       = Minute  * 60
    Day        = Hour    * 24
    Week       = Day     * 7
    Month      = Week    * 4
    Year       = Day     * 365
    Decade     = Year    * 10
    Century    = Decade  * 10
    Millennium = Century * 10
    Eon        = 1.0/0
  end

  def time_ago_in_words
    time_difference = Time.now.to_i - self.to_i
    unit = get_unit(time_difference)
    unit_difference = time_difference / Units.const_get(unit.capitalize)

    unit = unit.to_s.downcase + ('s' if time_difference > 1)

    "#{unit_difference} #{unit} ago"
  end

  private
  def get_unit(time_difference)
    Units.constants.each_cons(2) do |con|
      return con.first if (Units.const_get(con[0])...Units.const_get(con[1])) === time_difference
    end
  end
end