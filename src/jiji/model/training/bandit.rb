#!/usr/bin/env ruby

#====================
# bandit.rb
#====================

require './normal_dist_random'

class Bandit

  # size: 腕の数
  # reward_exp_avg: 各行動に対する報酬の期待値の平均
  # reward_exp_var: 各行動に対する報酬の期待値の分散
  # reward_var: 各行動に対する報酬の分散
  def initialize(size=10, reward_exp_avg=0.0, reward_exp_var=1.0, reward_var=1.0)
    @size = size
    @rand_generator = Array.new(size, 0)
    @reward_exp = Array.new(size, 0)
    random = NormalDistRandom.new(reward_exp_avg, reward_exp_var)
    size.times do |i|
      reward_exp = random.get_random
      @reward_exp[i] = reward_exp
      @rand_generator[i] = NormalDistRandom.new(reward_exp, reward_var)
    end
  end

  def select(i)
    return @rand_generator[i].get_random
  end

  attr_reader :size, :reward_exp
end

if __FILE__ == $PROGRAM_NAME
  bandit = Bandit.new
  puts "input 0 - #{bandit.size - 1}, or 'q'"
  STDIN.each_line do |c|
    c.chomp!
    case c
    when /[0-9]+/
      puts bandit.select(c.to_i)
    when "q"
      break
    else
      puts "input 0 - #{bandit.size - 1}, or 'q'"
    end
  end
  puts "expected values"
  p bandit.reward_exp
end
