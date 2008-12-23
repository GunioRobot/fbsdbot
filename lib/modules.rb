class Array
  def random
    self[rand(self.size - 1)]
  end
end

class String
  def random
    self[rand(self.size - 1)].chr
  end
end


module FBSDBot

  module Plugins
  end
  module Helpers
    class NickObfusicator

      @NICK_MAX_LEN = 9


      def NickObfusicator.run( old_nick )
        old_nick[rand(old_nick.size - 1)] = (rand(122-97) + 97).chr
        old_nick
      end

    end
    class Hostmask
      attr :exp
      def initialize(hostmask)
        @hostmask = hostmask
      end
      def match(exp)
        @exp = Regexp.new("^" + exp.gsub('*','.+?') + "$")
        return true	if( @exp.match(@hostmask) )
        false
      end
    end
  end


  module_function

  # call with FBSDBot::seconds_to_s etc.
  def seconds_to_s(seconds)
    seconds = seconds.round
    s = seconds % 60
    m = (seconds /= 60) % 60
    h = (seconds /= 60) % 24
    d = (seconds /= 24)
    out = []
    out << "#{d}d" if d > 0
    out << "#{h}h" if h > 0
    out << "#{m}m" if m > 0
    out << "#{s}s" if s > 0
    out.length > 0 ? out.join(' ') : '0s'
  end


  # thanks ROR!
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round

    case distance_in_minutes
    when 0..1
      return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
      case distance_in_seconds
      when 0..4   then 'less than 5 seconds'
      when 5..9   then 'less than 10 seconds'
      when 10..19 then 'less than 20 seconds'
      when 20..39 then 'half a minute'
      when 40..59 then 'less than a minute'
      else             '1 minute'
      end

    when 2..44           then "#{distance_in_minutes} minutes"
    when 45..89          then 'about 1 hour'
    when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
    when 1440..2879      then '1 day'
    when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
    when 43200..86399    then 'about 1 month'
    when 86400..525959   then "#{(distance_in_minutes / 43200).round} months"
    when 525960..1051919 then 'about 1 year'
    else                      "over #{(distance_in_minutes / 525960).round} years"
    end
  end


  # TODO: formatting codes can only use one letter, so some of these are commented out for now
  IRCColors = {
    # Colors
    "%k"    => "\x0301",  #black
    # "%db"   => "\x0302",  # dark blue
    "%g"    => "\x0303",  # green
    "%r"    => "\x0304",  # red
    # "%lr"   => "\x0304",  # light red
    # "%dr"   => "\x0305",  # dark red
    "%p"    => "\x0306",  # purple
    "%b"    => "\x0307",  # brown     # On some clients this is orange, others it is brown
    "%o"    => "\x0307",  # orange
    "%y"    => "\x0308",  # yellow
    "%a"    => "\x0310",  # aqua
    # "%lb"   => "\x0311",  # light blue
    "%b"    => "\x0312",  # blue
    "%v"    => "\x0313",  # violet
    # "%gr"    => "\x0314",  # grey
    # "%lg"   => "\x0315",  # light grey
    "%w"    => "\x0316",  # white

    # Other formatting
    "%n" => "\x0F", # normal
    "%B" => "\x02", # bold
    "%R" => "\x16", # reverse
  "%U" => "\x1F" } #underline

  def format_string(string)
    IRCColors.each_pair { |fmt, code| string.gsub!(fmt, code) }
    return string
  end

  def e_sh(str)
    str.to_s.gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/, '\\').gsub(/\n/, "'\n'").sub(/^$/, "''")
  end

end
