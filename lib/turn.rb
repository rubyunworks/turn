module Turn

  require 'optparse'
  #require 'turn'
  require 'turn/minitest_runner'
  require 'turn/rspec_runner'
  require 'turn/testunit_runner'

  #
  #def self.autorun
  #  true
  #end

  # Turn - Pretty Unit Test Runner for Ruby
  #
  # SYNOPSIS
  #   turn [OPTIONS] [RUN MODE] [OUTPUT MODE] [test globs...]
  #
  # OPTIONS
  #   -h --help             display this help information
  #      --live             don't use loadpath
  #      --log              log results to a file
  #   -n --name=PATTERN     only run tests that match regexp PATTERN
  #   -c --case=PATTERN     only run testcases that match regexp PATTERN
  #   -I --loadpath=PATHS   add given PATHS to the $LOAD_PATH
  #   -r --requires=LIBS    require given LIBS before running tests
  #   -b --backtrace=INT    Set the number of lines to show in backtrace.
  #
  # RUN MODES
  #      --normal      run all tests in a single process [default]
  #      --solo        run each test in a separate process
  #      --cross       run each pair of test files in a separate process
  #
  # OUTPUT MODES
  #   -O --outline     turn's original case/test outline mode [default]
  #   -P --progress    indicates progress with progress bar
  #   -D --dotted      test/unit's traditonal dot-progress mode
  #   -R --pretty      new pretty reporter
  #   -M --marshal     dump output as YAML (normal run mode only)
  #   -C --cue         interactive testing
  #
  class CLI

    # Shortcut for new.main(*argv)
    def self.run(*argv)
      new.call(*argv)
    end

    # Only run tests matching this pattern.
    attr :match_test

    # Only run testcases matching this pattern.
    attr :match_case

    # List of paths to add to $LOAD_PATH
    attr :loadpath

    # Libraries to require before running tests.
    attr :requires

    # Framework to use: rubytest, minitest, rspec, testunit.
    #attr :framework

    ## Run mode.
    #attr :runmode

    # Output format.
    attr :reporter

    # Backtrace depth.
    attr :trace

    # Use natural test case names.
    attr :natural

    # Force ANSI use on or off.
    attr :ansi

    # Log output.
    attr :log

    # Do not use local loadpath.
    attr :live

    #
    attr :debug

    #
    def debug?
      @debug
    end

    #
    def initialize
      @live      = nil
      @log       = nil
      @pattern   = nil
      @matchcase = nil
      @loadpath  = []
      @requires  = []
      #@runmode   = nil
      @reporter  = nil
      @trace     = nil
      @natural   = false
      @ansi      = true
    end

    #
    def option_parser
      OptionParser.new do |opts|

        opts.banner = "Turn - Pretty Unit Test Runner for Ruby"

        opts.separator " "
        opts.separator "SYNOPSIS"
        opts.separator "  turn [OPTIONS] [RUN MODE] [OUTPUT MODE] [TEST GLOBS ...]"

        opts.separator " "
        opts.separator "GENERAL OPTIONS"

        opts.on('-I', '--loadpath=PATHS', "add paths to $LOAD_PATH") do |path|
          @loadpath.concat(path.split(':'))
        end

        opts.on('-r', '--require=LIBS', "require libraries") do |lib|
          @requires.concat(lib.split(':'))
        end

        opts.on('-n', '--name=PATTERN', "only run tests that match PATTERN") do |pattern|
          if pattern =~ /\/(.*)\//
            @match_test = Regexp.new($1)
          else
            @match_test = Regexp.new(pattern, Regexp::IGNORECASE)
          end
        end

        opts.on('-c', '--case=PATTERN', "only run test cases that match PATTERN") do |pattern|
          if pattern =~ /\/(.*)\//
            @match_case = Regexp.new($1)
          else
            @match_case = Regexp.new(pattern, Regexp::IGNORECASE)
          end
        end

        opts.on('-b', '--backtrace', '--trace INT', "Limit the number of lines of backtrace.") do |int|
          @trace = int
        end

        opts.on('--natural', "Show natualized test names.") do |bool|
          @natural = bool
        end

        opts.on('--[no-]ansi', "Force use of ANSI codes on or off.") do |bool|
          @ansi = bool
        end

        opts.on('--live', "do not use local load path") do
          @live = true
        end

        #opts.on('--log', "log results to a file") do #|path|
        #  @log = true # TODO: support path/file
        #end

        #opts.separator " "
        #opts.separator "FRAMEWORK"

        # Turn does not support Test::Unit 2.0+
        #opts.on('-u', '--testunit', "Force use of TestUnit framework") do
        #  @framework = :testunit
        #end

        #opts.separator " "
        #opts.separator "RUN MODES"

        #opts.on('--normal', "run all tests in a single process [default]") do
        #  @runmode = nil
        #end

        #opts.on('--solo', "run each test in a separate process") do
        #  @runmode = :solo
        #end

        #opts.on('--cross', "run each pair of test files in a separate process") do
        #  @runmode = :cross
        #end

        opts.separator " "
        opts.separator "OUTPUT MODES"

        opts.on('-f', '--format NAME', "select a custom report format") do |name|
          @reporter = name.to_s
        end

        opts.on('--outline', '-O', "turn's original testcase outline mode [default]") do
          @reporter = 'outline'
        end

        opts.on('--progress', '-P', "indicates progress with progress bar") do
          @reporter = 'progress'
        end

        opts.on('--dot', '-D', "test-unit's traditonal dot-progress mode") do
          @reporter = 'dot'
        end

        opts.on('--runtime', '-R', "run tests alongside running time") do
          @reporter = 'runtime'
        end

        #opts.on('--pretty', "new pretty output mode") do
        #  @reporter = 'runtime'
        #end

        #opts.on('--cue', '-C', "cue for action on each failure/error") do
        #  @reporter = :cue
        #end

        opts.on('--tap', '-T', "legacy Perl-style TAP format") do
          @reporter = 'tap'
        end

        # TODO pass thru YAML or JSON
        #opts.on('--marshal', '-M', "dump output as YAML") do
        #  #@runmode  = :marshal
        #  @reporter = :marshal
        #end

        opts.separator " "
        opts.separator "COMMAND OPTIONS"

        opts.on('--debug', "turn debug mode on") do
          @debug = true
        end

        opts.on_tail('--version', "display version") do
          puts VERSION
          exit
        end

        opts.on_tail('--help', '-h', "display this help information") do
          puts opts
          exit
        end
      end
    end

    #
    # Run the command.
    #
    def call(*argv)
      option_parser.parse!(argv)

      @loadpath = ['lib'] if loadpath.empty? && !live

      loadpath.each{ |f| $:.unshift f }
      requires.each{ |f| require(f)   }

      format = reporter || ENV['rpt']

      runner = Turn.runners.find{ |runner| runner.use? }

      runner.run(
        :files  => argv,
        :format => reporter,
        :trace  => trace,
        :ansi   => ansi
      )
    end

  end

end
