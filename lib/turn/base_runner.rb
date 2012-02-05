module Turn

  require 'tapout'

  #
  def self.runners
    @runners ||= []
  end

  # Base class for all runners.
  #
  class BaseRunner

    def self.inherited(subclass)
      Turn.runners << subclass
    end

    #
    def self.run(options={})
      new(options).run
    end

    #
    def initialize(options={})
      @files  = options[:files]
      @format = options[:format] || 'turn'
      @trace  = options[:trace]  || 3
      @ansi   = options[:ansi]

      #Tapout.config.format = @format
      Tapout.config.trace = @trace
      #Tapout.config.ansi  = @ansi unless @ansi.nil?
    end

    #
    def run
    end

  end

end
