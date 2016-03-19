#====================
# normal_dist_random.rb
#--------------------
# 正規分布に従う乱数生成器
#====================

class NormalDistRandom
  include Math

  @@random = Random.new

  # 期待値exp, 分散varの正規分布に従った乱数を生成する
  # 乱数生成器を作成する。
  def initialize(exp=0.0, var=1.0)
    @exp = exp
    @var = var
    @values = Array.new(0)
  end

  def get_random
    if @values.size == 0
      # ボックス＝ミュラー法で乱数を生成する

      # NOTE
      # Random#randは[0, 1)で値を返すので、
      # (0, 1]に変換する。
      a = 1.0 - @@random.rand
      b = 1.0 - @@random.rand

      z1 = sqrt(-2.0 * log(a)) * cos(2 * PI * b)
      z2 = sqrt(-2.0 * log(a)) * sin(2 * PI * b)

      rand1 = z1 * sqrt(@var) + @exp
      rand2 = z2 * sqrt(@var) + @exp

      @values.push(rand1, rand2)
    end

    return @values.shift
  end
end
