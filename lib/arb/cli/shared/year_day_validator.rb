module Arb
  module Cli
    class YearDayValidator
      def self.validate_year_and_day(year:, day:, default_untracked_or_done: false)
        year, day = year&.to_s, day&.to_s

        # The first two digits of the year may be omitted.
        year = "20#{year}" if year && year.length == 2

        if day && !year
          raise InputError, "If you specify the day, specify the year also."
        elsif !day
          if default_untracked_or_done
            year, day = Git.new_solutions.last
          end

          unless day
            if year && !Dir.exist?(File.join("src", year))
              Dir.mkdir(File.join("src", year))
              day = "1"
            else
              year, day = Git.last_committed_solution(year:)

              if day && !default_untracked_or_done
                if day == "25"
                  day = :end
                else
                  day = day.next
                end
              end

              if !day || day == :end
                default_year = "2015"
                default_day = "1"
                bootstrap_year_prompt = nil

                committed = Git.committed_by_year
                total_committed = committed.values.sum { _1.values.count(&:itself) }
                if total_committed.zero?
                  bootstrap_year_prompt = "What year's puzzles do you want to start with? (default: #{default_year})"
                else
                  earliest_year_with_fewest_committed = committed
                    .transform_values { _1.values.count(&:itself) }
                    .sort_by(&:last).first.first
                  default_year = earliest_year_with_fewest_committed
                  default_day = committed[default_year].values.index(false)

                  puts "You've recently finished #{year}. Yay!"
                  bootstrap_year_prompt = "What year do you want to bootstrap next? (default: #{default_year} [at Day #{default_day}])"
                end

                loop do
                  puts bootstrap_year_prompt
                  print PASTEL.green("> ")
                  year_input = STDIN.gets.strip
                  puts
                  if year_input.strip.empty?
                    year = default_year
                    day = default_day
                  else
                    year = year_input.strip.match(/\A\d{4}\z/)&.to_s
                    day = "1"
                  end
                  break if year
                end
              end
            end
          end
        end

        year = Integer(year, exception: false) || (raise InputError, "Year must be a number.")
        day = Integer(day, exception: false) || (raise InputError, "Day must be a number.")

        unless year.between?(2015, Date.today.year)
          raise InputError, "Year must be between 2015 and this year."
        end
        unless day.between?(1, 25) && Date.new(year, 12, day) <= Date.today
          raise InputError, "Day must be between 1 and 25, and <= today."
        end

        [year.to_s, day.to_s]
      end
    end
  end
end
