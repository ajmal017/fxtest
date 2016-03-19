#====================
# value_nn.rb
#--------------------
# 価値ベクトルを関数近似するためのニューラルネットワーク
#
# 中間層では、以下の活性化関数を使う：
#   f(u) = u     (u >= 0)
#          0.1*u (otherwise)
# なお、この導関数は
#   f'(u) = 1   (u >= 0)
#           0.1 (otherwise)
#
# 出力層では、以下の活性化関数を使う：
#   f(u) = u   (output_min <= u <= output_max)
#          0.1u + 0.9output_max (output_max < u)
#          0.1u + 0.9output_min (u < output_min)
# なお、この導関数は
#   f'(u) = 1   (output_min <= u <= output_max)
#           0.1 (otherwise)
#
# また、ドロップアウトも使える。（未実装）
#====================

require_relative "normal_dist_random"

class ValueNN
  def initialize(input_size, hidden_unit_size, output_min, output_max)
    @input_size = input_size
    @hidden_unit_size = hidden_unit_size
    @output_min = output_min
    @output_max = output_max

    hidden_unit_weight_variance = 1.0 / (@input_size + 1.0)
    hidden_unit_weight_generator = NormalDistRandom.new(0.0, hidden_unit_weight_variance)
    @hidden_units_weights = Array.new
    @hidden_units_bias = Array.new
    @hidden_unit_size.times do
      weights = Array.new(@input_size) do
        hidden_unit_weight_generator.get_random
      end
      bias = hidden_unit_weight_generator.get_random
      @hidden_units_weights.push(weights)
      @hidden_units_bias.push(bias)
    end

    output_unit_weight_variance = 1.0 / (@hidden_unit_size + 1.0)
    output_unit_weight_generator = NormalDistRandom.new(0.0, output_unit_weight_variance)
    @output_unit_weights = Array.new(@hidden_unit_size) do
      output_unit_weight_generator.get_random
    end
    @output_unit_bias = output_unit_weight_generator.get_random
  end

  def get_value_and_weights_gradient(input, drop_rate=0.0)
    # calculate output by forward propagation
    hidden_units_output = Array.new
    hidden_units_activation_gradient = Array.new
    @hidden_unit_size.times do |hidden_unit_index|
      input_sum = @hidden_units_bias[hidden_unit_index]
      @input_size.times do |input_index|
        input_sum += @hidden_units_weights[hidden_unit_index][input_index] * input[input_index]
      end
      output, activation_gradient = hidden_unit_activation_and_gradient(input_sum)
      hidden_units_output.push output
      hidden_units_activation_gradient.push activation_gradient
    end

    hidden_units_output_sum = @output_unit_bias
    @hidden_unit_size.times do |hidden_unit_index|
      hidden_units_output_sum += @output_unit_weights[hidden_unit_index] * hidden_units_output[hidden_unit_index]
    end
    output_unit_output, output_unit_activation_gradient = output_unit_activation_and_gradient(hidden_units_output_sum)

    # calculate delta by back propagation

    output_unit_delta = output_unit_activation_gradient

    hidden_units_delta = Array.new
    @hidden_unit_size.times do |hidden_unit_index|
      delta = output_unit_delta * @output_unit_weights[hidden_unit_index] * hidden_units_activation_gradient[hidden_unit_index]
      hidden_units_delta.push delta
    end

    # calculate weights gradient

    weights_gradient = Array.new
    @hidden_unit_size.times do |hidden_unit_index|
      hidden_unit_delta = hidden_units_delta[hidden_unit_index]
      weights_gradient.push hidden_unit_delta # hidden unit bias gradient
      @input_size.times do |input_index|
        hidden_unit_weight_gradient = hidden_unit_delta * input[input_index]
        weights_gradient.push hidden_unit_weight_gradient
      end
    end
    weights_gradient.push output_unit_delta # output unit bias gradient
    @hidden_unit_size.times do |hidden_unit_index|
      output_unit_weight_gradient = output_unit_delta * hidden_units_output[hidden_unit_index]
      weights_gradient.push output_unit_weight_gradient
    end

    [output_unit_output, weights_gradient]
  end

  def get_value_with_weights_gradient(input, weights_gradient, alpha=1.0)
    weights_gradient_copy = weights_gradient.dup

    # calculate output by forward propagation, with weights_gradient

    hidden_units_output = Array.new
    @hidden_unit_size.times do |hidden_unit_index|
      input_sum = @hidden_units_bias[hidden_unit_index] + alpha * weights_gradient_copy.shift
      @input_size.times do |input_index|
        input_sum += (@hidden_units_weights[hidden_unit_index][input_index] + alpha * weights_gradient_copy.shift) * input[input_index]
      end
      output, _ = hidden_unit_activation_and_gradient(input_sum)
      hidden_units_output.push output
    end

    hidden_units_output_sum = @output_unit_bias + alpha * weights_gradient_copy.shift
    @hidden_unit_size.times do |hidden_unit_index|
      hidden_units_output_sum += (@output_unit_weights[hidden_unit_index] + alpha * weights_gradient_copy.shift) * hidden_units_output[hidden_unit_index]
    end
    output_unit_output, _ = output_unit_activation_and_gradient(hidden_units_output_sum)

    output_unit_output
  end

  def get_weights
    weights = Array.new
    @hidden_unit_size.times do |hidden_unit_index|
      weights.push @hidden_units_bias[hidden_unit_index]
      @input_size.times do |input_index|
        weights.push @hidden_units_weights[hidden_unit_index][input_index]
      end
    end
    weights.push @output_unit_bias
    @hidden_unit_size.times do |hidden_unit_index|
      weights.push @output_unit_weights[hidden_unit_index]
    end
    weights
  end

  def add_weights(weights_diff)
    weights_diff_copy = weights_diff.dup
    @hidden_unit_size.times do |hidden_unit_index|
      @hidden_units_bias[hidden_unit_index] += weights_diff_copy.shift
      @input_size.times do |input_index|
        @hidden_units_weights[hidden_unit_index][input_index] += weights_diff_copy.shift
      end
    end
    @output_unit_bias += weights_diff_copy.shift
    @hidden_unit_size.times do |hidden_unit_index|
      @output_unit_weights[hidden_unit_index] += weights_diff_copy.shift
    end
  end

  private

  def hidden_unit_activation_and_gradient(u)
    if u >= 0.0
      [u, 1.0]
    else
      [0.1 * u, 0.1]
    end
  end

  def output_unit_activation_and_gradient(u)
    if u < @output_min
      [0.1 * u + 0.9 * @output_min, 0.1]
    elsif u <= @output_max
      [u, 1.0]
    else
      [0.1 * u + 0.9 * @output_max, 0.1]
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require "pp"

  value_nn = ValueNN.new(3, 10, -1.0, 1.0)
  pp value_nn

  [
    [1.0, 1.0, 1.0],
    [1.0, 1.0, 0.0],
    [1.0, 0.0, 1.0],
    [0.0, 1.0, 1.0],
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
    [0.0, 0.0, 1.0],
    [0.0, 0.0, 0.0],
  ].each do |input|
    output, weights_gradient = value_nn.get_value_and_weights_gradient(input)
    output_with_weights_gradient = value_nn.get_value_with_weights_gradient(input, weights_gradient)
    diff = output_with_weights_gradient - output

    alpha = 1.0
    upper_bound = nil
    lower_bound = nil
    last = 100
    100.times do |t|
      if diff < 0.0
        upper_bound = alpha
        if lower_bound.nil?
          alpha /= 2.0
        else
          alpha = (upper_bound + lower_bound) / 2.0
        end
      elsif diff < 0.9
        lower_bound = alpha
        if upper_bound.nil?
          alpha /= diff
        else
          alpha = (upper_bound + lower_bound) / 2.0
        end
      elsif diff > 1.1
        upper_bound = alpha
        if lower_bound.nil?
          alpha /= diff
        else
          alpha = (upper_bound + lower_bound) / 2.0
        end
      else
        last = t
        break
      end

      output_with_weights_gradient_and_alpha = value_nn.get_value_with_weights_gradient(input, weights_gradient, alpha)
      diff = output_with_weights_gradient_and_alpha - output
    end

    output_with_01alpha = value_nn.get_value_with_weights_gradient(input, weights_gradient, 0.1 * alpha)
    diff_01alpha = output_with_01alpha - output

    puts "input: #{input}, output: #{output}"
    puts "  alpha: #{alpha}, iterations: #{last}"
    puts "  diff (alpha): #{diff}, diff (0.1*alpha): #{diff_01alpha}"

    weights_diff = weights_gradient.map{|i| i * 0.1 * alpha}
    value_nn.add_weights(weights_diff)
    new_output, _ = value_nn.get_value_and_weights_gradient(input)
    new_diff = new_output - output
    puts "  new output: #{new_output}, diff: #{new_diff}"
  end
end
