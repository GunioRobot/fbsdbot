require 'lib/irc/event_commands'
require 'lib/irc/event_constants'

module FBSDBot
  module IRC
    class EMCore < EventMachine::Connection
      attr_reader :args, :start_time
      include EventMachine::Deferrable
      include Commands
      include Constants

      def self.connect(args = {})
        args[:port]     ||= 6667
        args[:username] ||= args[:nick]
        args[:realname] ||= args[:nick]
         
        EventMachine::connect( args[:host], args[:port], self) do |instance| 
          instance.instance_eval {
            @args = args
            @event_producer = EventProducer.new(self)
            Log.info("Connecting to server", self)
          }
        end
      end
      
      def to_s
        "<Worker ##{object_id}::(#{@connected ? "C" : "D"}:#{@args[:host]})>"
      end
      
      def post_init
        @start_time = Time.now
        @buffer = ""
        @connected = false
        @shutdown = false
      end
      
      def connection_completed
        @connected = true
        Log.info("Sending login information", self)
        login
      end
      
      def receive_data(data)
        lines = 0
        data.each_line(EOL) do |line|
          next if line == EOL
          if line =~ EXP_EOL 
            lines += 1 
            produce_event(line) 
          else
            @buffer << line
          end
        end
        
        lines
      end

      def produce_event(line)
        message = @buffer.empty? ? line : @buffer + line
        @buffer = "" # important, reset buffer!
        
        # for tests only.. TODO: improve this
        @event_producer = EventProducer.new(nil) if(@event_producer.nil?)

        handle_event(@event_producer.parse_line(message))
      end
      
      def handle_event(event)
        return if event.nil?
        raise TypeError, "Not passed an Event.class" unless event.is_a?(Event)
        
        case(event)
        when EndOfMotdEvent
          join_channels(*@args[:channels])
        when NicknameInUseEvent
          change_nick Helpers::NickObfusicator.run(@args[:nick])
        else
          ## CREATE cases above for events we don't want plugins to be able to handle
          Plugin.find_plugins(event)
        end
      end
     
      def unbind
        @connected = false
        Log.info("Disconnected", self)
        reconnect(@args[:host], @args[:port]) unless(@shutdown)
        succeed(self) # send status to handle if this is good or bad, this might not allways be a good thing.. 
      end
      
    end
  end
end