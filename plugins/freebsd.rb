require 'net/http'
require 'cgi'

# =====================================
# = Plugin for FreeBSD-specific stuff =
# =====================================

FBSDBot::Plugin.define("freebsd") {
   author "jp_tix"
   version "0.0.2"
   commands %w{whatis man ports doc}

   class FreeBSD
      # display output from the whatis shell command
      def whatis(line)
         if !line or line.empty?
            return 'USAGE: whatis <search string>'
         else
            return %x{whatis "#{FBSDBot::e_sh(line)}"}
         end
      end # method whatis

      # command to look up man pages (name + synopsis)
      def man(action, line)

         if !line or line.empty?
            action.reply 'USAGE: man <search string>'
            return
         end

         line = line.strip
         man_html = %x{man '#{FBSDBot::e_sh(line)}' | groff -man -Thtml 2>/dev/null}
         if man_html =~ /<p.*>NAME(.+?)<\/p>.+?<p.*>SYNOPSIS(.+?)<\/p>/m
            name, synop = $1, $2
            name = name.gsub('<b>', "\x02").gsub('</b>', "\x0f").gsub(/<.+?>/, '').gsub("\n", '').strip
            synop = synop.gsub('<b>', "\x02").gsub('</b>', "\x0f").gsub(/<.+?>/, '').strip
            cmd = name =~ /^(.+) --?/ ? $1 : line
            link = "http://www.freebsd.org/cgi/man.cgi?query=#{CGI.escape(line)}"
            action.reply CGI.unescapeHTML("#{name} ( #{link} )")
            synop.gsub(/\n|\t/, ' ').gsub(cmd, "\n" + cmd).split("\n").each_with_index do |line, index|
               action.reply(CGI.unescapeHTML(line)) unless line.empty? or index > 3
               sleep(0.2)
            end
         else
            action.reply "No manual entry for #{line}"
         end
      end # command man

      def ports(action, line)

         if !line or line.empty?
            action.reply('USAGE: ports <search string>')
            return
         end

         Net::HTTP.start('www.freshports.org') do |http|
            re = http.get("/search.php?query=#{CGI.escape(line.strip)}&search=go&num=10&stype=name&method=match&deleted=excludedeleted&start=1&casesensitivity=caseinsensitive", { 'User-Agent' => 'FBSDBot' })
            if re.code == '200'
               ports = []
               re.body.scan(/<BIG><B>(.+?)<\/B>.+?<code class="code">(.+?)<\/code>/m) { |match| ports << match  }
               if ports.empty?
                  action.reply 'No ports found.'
               else
                  ports.each_with_index do |port, index|
                     if port[0] =~ /<a href="(.+?)">(.+?)<\/a>(.+)/
                        link, name, version = $1, $2, $3
                        action.reply "\x02#{name.strip}\x0f - #{version.strip} => #{port[1]}"
                        action.reply "     ( #{'http://www.freshports.org' + link} )"
                        sleep(0.2)
                     else
                        action.reply "Parse error."
                     end unless index > 2
                  end
               end
            else
               action.reply "Freshports.org returned an error: #{re.code} #{re.message}"
            end
         end
      end # method ports

      def doc(action, line)

         if !line or line.empty?
            action.reply('USAGE: doc <search string>')
            return
         end

         Net::HTTP.start('www.freebsd.org') do |http|
            re = http.get("/cgi/search.cgi?words=#{CGI.escape(line)}&max=5&source=www", { 'User-Agent' => 'FBSDBot' })
            if re.code == '200'
               if re.body =~ /<div id="content">(.+?)<\/div>/m
                  content = $1
                  if content =~ /Nothing found/m
                     action.reply("Nothing found.")
                     return
                  else
                     links = []
                     content.scan(/<li><a href="(.+?)"/) { |match| links << match[0]  }
                     links.each_with_index { |link, index| action.reply link unless index > 4; sleep(0.2) }
                  end
               end
            else
               action.reply "FreeBSD.org returned an error: #{re.code} #{re.message}"
            end
         end
      end # method doc


   end # class FreeBSD

   # instantiate class
   @freebsd = FreeBSD.new

   # ==================
   # = Action Hooks =
   # ==================

   def on_msg_whatis(action)
      action.reply @freebsd.whatis(action.message)
   end

   def on_msg_man(action)
      @freebsd.man(action, action.message)
   end

   def on_msg_ports(action)
      @freebsd.ports(action, action.message)
   end

   def on_msg_doc(action)
      @freebsd.doc(action, action.message)
   end
}
