# SYMBOLS
"pubmsg".to_sym
"privmsg".to_sym
"ctcp".to_sym
"on_join".to_sym
"on_msg".to_sym
"on_ctcp".to_sym
"on_part".to_sym
"on_quit".to_sym

module FBSDBot

  module PluginSugar
    def def_field(*names)
      class_eval do
        names.each do |name|
          define_method(name) do |*args|
            case args.size
            when 0: instance_variable_get("@#{name}")
            else    instance_variable_set("@#{name}", [*args])
            end
          end
        end
      end
    end
  end

  class Plugin
    @registered_plugins = {}
    class << self
      attr_reader :registered_plugins
      private :new
    end

    def self.list_plugins
      @registered_plugins.each {|i,p| Log.info "Written by #{p.author}", p}
    end

    def self.define(name, &block)
      p = new
      p.instance_eval(&block)
      p.instance_eval { name(name) }
      
      Plugin.registered_plugins[name.to_sym] = p
    end
    
    def to_s
        "#<FBSDBot::Plugin: #{@name}, #{@version}>"
    end

    def self.find_plugins(name, event)
      found = false
      @registered_plugins.each do |i,p|
        if p.respond_to?(name)
          $bot.command_count += 1 if event.command?
          p.send(name,event)
          found = true
        end
      end

      return found
    end

    extend PluginSugar
    def_field :name, :author, :version, :commands
  end

end
