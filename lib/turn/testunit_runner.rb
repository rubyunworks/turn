module Turn

  require 'turn/base_runner'

  # Runner for TestUnit
  #
  class TestUnitRunner < BaseRunner

    #
    def self.use?
      Dir['test/test*.rb'].first ? true : false
    end

  end

end

