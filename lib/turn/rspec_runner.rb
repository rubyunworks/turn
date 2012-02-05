module Turn

  require 'turn/base_runner'

  # Runner for RSpec
  #
  class RSpecRunner < BaseRunner

    #
    def self.use?
      Dir['spec/*_spec.rb'].first ? true : false
    end

    #
    def run
      require 'rspec'
      require 'rspec/ontap'
      require 'thread'

      files = @files.join(' ')

      r, w = IO.pipe

      e = $stderr  # maybe StringIO ?

      stream_parser = Tapout::YamlParser.new(:format=>@format)

      #return if autorun_disabled? || installed_at_exit? || running_in_drb?
      #at_exit { exit run(ARGV, $stderr, $stdout).to_i }
      #@installed_at_exit = true

      at_exit {
        next if $!  # forget it if there was an exception

        exit_code = nil

        at_exit { exit false if exit_code && exit_code != 0 }

        Thread.new do
          exit_code = ::RSpec::Core::Runner.run(['-f', 'TapY', *files], e, w).to_i
          w.close
        end.run

        exit_code = stream_parser.consume(r)
      }
    end

  end

end

