module Turn

  require 'turn/base_runner'

  # Runner for MiniTest
  #
  class MiniTestRunner < BaseRunner

    #
    def self.use?
      Dir['test/*_test.rb'].first ? true : false
    end

    #
    def initialize(options={})
      super(options)
    end

    #
    # Autorun for MiniTest
    #
    def run
      require 'minitest/unit'
      require 'minitap'
      require 'thread'

      @files.each{ |f| require(File.expand_path(f)) }

      r, w = IO.pipe

      ::MiniTest::Unit.runner = ::MiniTest::TapY.new
      ::MiniTest::Unit.output = w

      stream_parser = Tapout::YamlParser.new(:format=>@format)

      #at_exit {
      #  w.close
      #  exit_code = stream_parser.consume(r)
      #}
      #MiniTest::Unit.autorun

      at_exit {
        next if $!  # forget it if there was an exception

        exit_code = nil

        at_exit { exit false if exit_code && exit_code != 0 }

        Thread.new do
          exit_code = ::MiniTest::Unit.new.run #(argv)
          w.close
        end.run

        exit_code = stream_parser.consume(r)
      }
    end

    #
    # TODO: Produce the equivalent command line call.
    #
    def shell_command(files, options={})
      loadpath = options[:loadpath]
      requires = options[:requires]

      cmd = []
      cmd << "ruby"  # "bundle exec ruby"
      cmd << loadpath.map{ |i| %{-I"#{i}"} }.join(' ') unless loadpath.empty?
      cmd << requires.map{ |r| %{-r"#{r}"} }.join(' ') unless requires.empty?
      #cmd << "-r minitest/unit"
      cmd.concat(files)
      cmd << "| tapout"
      cmd << "-t #{trace}" if @trace
      cmd << "--no-ansi" unless @ansi
      cmd << @format
      cmd = cmd.join(' ')

      return cmd

      #puts cmd if $DEBUG
      #system cmd
    end

  end

end
