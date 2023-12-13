module EffectiveTestBotPerformance
  def assert_performance(milliseconds: 250, print_results: false, &block)
    result = performance_test(print_results: print_results, &block)

    assert (result < milliseconds), "Expected performance to be less than #{milliseconds}ms, but it was #{result}ms"
  end

  def performance_test(warmups: 2, iterations: 10, print_results: true, &block)
    raise('expected a block') unless block_given?
    raise('please install the ruby-prof gem') unless defined?(RubyProf)

    # Warmup
    warmups.times { block.call() }

    # Use ruby-prof to Profile
    profile = RubyProf::Profile.new(track_allocations: true)

    results = profile.profile do
      iterations.times do
        print '.'
        block.call()
      end
    end

    # Return a single number result
    milliseconds = ((results.threads.sum { |thread| thread.total_time } * 1000.0) / iterations.to_f).round

    # Print results
    print_performance_test_results(results, milliseconds) if print_results

    # Returns an integer number of milliseconds
    milliseconds
  end

  private

  def print_performance_test_results(results, milliseconds)
    puts('')

    path = Rails.application.root.join('tmp')

    # Profile Graph
    filename = path.join('profile-graph.html')
    File.open(filename, 'w+') { |file| RubyProf::GraphHtmlPrinter.new(results).print(file) }
    puts("Profile Graph: #{filename}")

    # Profile Flat
    filename = path.join('profile-flat.txt')
    File.open(filename, 'w+') { |file| RubyProf::FlatPrinter.new(results).print(file) }
    puts("Profile Flat: #{filename}")

    # Profile Stack
    filename = path.join('profile-stack.html')
    File.open(filename, 'w+') { |file| RubyProf::CallStackPrinter.new(results).print(file) }
    puts("Profile Stack: #{filename}")

    # Total Performance
    puts "Performance: #{milliseconds}ms"

    puts('')
  end
end
