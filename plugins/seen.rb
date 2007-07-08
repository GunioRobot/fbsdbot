
# ===============
# = Seen plugin =
# ===============


FBSDBot::Plugin.define("seen") {
   author "jp_tix"
   version "0.0.1"

   class Seen
      def initialize
         self.load
         @botroot_path = File.dirname(__FILE__) + "/../"
      end

      def log_event(nick, channel, event_type, message = '')
         # puts "Logged #{event_type.to_s} for #{nick}"  #    <-- DEBUG
         @seen[nick] = [event_type, message, Time.now, channel]
      end

      def seen_nick(action, nick)
         if nick == $bot.nick
            action.reply "I'm right here."
         elsif @seen.has_key?(nick)
            time = FBSDBot.distance_of_time_in_words(@seen[nick][2], Time.now, true)
            # time = FBSDBot.seconds_to_s(Time.now.to_i - @seen[nick][2].to_i)
            info = @seen[nick]
            action.reply "#{nick} " + case info[0]
            when :msg: "said '#{info[1]}' in #{info[3]}, #{time} ago."
            when :part: "left #{info[3]} #{time} ago" + (info[1].empty? ? '.' : ", saying: #{info[1]}.")
            when :join: "joined #{info[3]} #{time} ago."
            when :quit: "quit IRC #{time} ago" +  (info[1].empty? ? '.' : ", saying: #{info[1]}.")
            end
         else
            best_match = ''
            shortest_distance = 50
            @seen.each_key do |known_nick|
               dist = edit_distance(known_nick.downcase, nick.downcase)
               if dist < shortest_distance
                  best_match = known_nick
                  shortest_distance = dist
               end
            end
              if shortest_distance <= (nick.size + best_match.size.to_f) / 2.0 * 0.70
               action.reply "Indeed I have not. Perhaps you're looking for #{best_match}?"
              else
               action.reply "Nope."
              end
            end
            self.save
         end

         def save
            File.open(@botroot_path + "seen.yaml", "w") { |io| YAML.dump(@seen, io) }
         end

         def load
            begin
               @seen = YAML.load_file(@botroot_path + 'seen.yaml')
            rescue
               @seen = {}
            end
         end

         def edit_distance(a, b)
            return 0 if !a || !b || a == b
            return (a.length - b.length).abs if a.length == 0 || b.length == 0
            m = [[0]]
            1.upto(a.length) { |i| m[i] = [i] }
            1.upto(b.length) { |j| m[0][j] = j }
            1.upto(a.length) do |i|
               1.upto(b.length) do |j|
                  m[i][j] =
                  [ m[i-1][j-1] + (a[i-1] == b[j-1] ? 0 : 1),
                  m[i-1][j] + 1,
                  m[i][j-1] + 1                             ].min
               end
            end
            m[a.length][b.length]
         end

      end

      @logger = Seen.new

      def on_msg(action)
         @logger.log_event(action.nick, action.channel, :msg, action.message) unless action.type == :privmsg
      end

      def on_part(action)
         @logger.log_event(action.nick, action.channel, :part, action.message)
      end

      def on_join(action)
         @logger.log_event(action.nick, action.channel, :join)
      end

      def on_quit(action)
         @logger.log_event(action.nick, nil, :quit, action.message)
      end

      def on_msg_seen(action)
         @logger.seen_nick(action, action.message)
      end

      def on_shutdown
        @logger.save
      end

   }
