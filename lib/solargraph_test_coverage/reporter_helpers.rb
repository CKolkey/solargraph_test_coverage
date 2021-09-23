# frozen_string_literal: true

module SolargraphTestCoverage
  # Some helper functions for the diagnostics
  module ReporterHelpers
    # @return [Hash]
    def run_test(source)
      ForkProcess.call do
        Coverage.start(lines: true, branches: true)
        runner = TestRunner.with(test_file(source)).run!
        Coverage.result.fetch(source.location.filename, {}).merge({ test_status: runner.passed? })
      end
    end

    def messages(source, results)
      messages = [
        line_warnings(source, results),
        branch_warnings(source, results),
        test_passing_error(source, results)
      ]

      messages.flatten.compact
    end

    def line_warnings(source, results)
      uncovered_lines(results).map { |line| line_coverage_warning(source, line) }
    end

    def branch_warnings(source, results)
      uncovered_branches(results).map { |branch| branch_coverage_warning(source, branch.report) }
    end

    def test_passing_error(source, results)
      results[:test_status] ? [] : [test_failing_error(source)]
    end

    # Adapted from SingleCov
    # Coverage returns nil for untestable lines (like 'do', 'end', 'if' keywords)
    # otherwise returns int showing how many times a line was called
    #
    #  [nil, 1, 0, 1, 0] -> [3, 5]
    #  Returns array of line numbers with 0 coverage
    def uncovered_lines(results)
      return [] unless results[:lines]

      results[:lines].each_with_index
                     .select { |c, _| c&.zero? }
                     .map { |_, i| i }
                     .compact
    end

    def uncovered_branches(results)
      Branch.build_from(results).reject(&:covered?)
    end

    def range(start_line, start_column, end_line, end_column)
      Solargraph::Range.from_to(start_line, start_column, end_line, end_column).to_hash
    end

  end
end
