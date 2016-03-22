
require 'jiji/model/agents/agent'
require 'jiji/model/training/value_nn'

# ===移動平均を使うエージェントのサンプル
# 添付ライブラリ Signals::MovingAverage を利用して移動平均を算出し、
# デッドクロスで売、ゴールデンクロスで買注文を行います。
# また、算出した移動平均値をグラフに出力します。
class MovingAverageAgent

  include Jiji::Model::Agents::Agent

  def self.description
    <<-STR
 -人工知能使ってみよう
 -次のレートがUPするかDOWNするかを予想してもらう
      STR
  end

  # UIから設定可能なプロパティの一覧
  def self.property_infos
    [
      Property.new('short', '短期移動平均線', 25),
      Property.new('long',  '長期移動平均線', 75)
    ]
  end

  def post_create
    # 移動平均の算出クラス
    # 共有ライブラリのクラスを利用。
    @mvs = [
      Signals::MovingAverage.new(@short.to_i),
      Signals::MovingAverage.new(@long.to_i)
    ]
    @cross = Cross.new

    # 移動平均グラフ
    @graph = graph_factory.create('移動平均線',
      :rate, :average, ['#779999', '#557777'])

    # AIの器を作成する、もし学習結果がすでにあればそれを読み込む
    @nn = ValueNN.new

  end

  # 次のレートを受け取る
  def next_tick(tick)
    # 各種データを取得したい
    # 始値、終値、高値、安値
    # 移動平均
    # ボリンジャーバンド
    # RSI、DMI

    # ゆくゆくはデータ保孫、学習のエージェントは別作成する
    # データの保存は、学習のためだけ、呼び出しも学習のためだけだが
    # 学習した時と同じフォーマットで渡したいので、保存クラスに現在レートから欲しい情報を生成するメソッドを作成するべき
    # もしくは、情報生成クラスを別に作って、保存クラスから、エージェントから呼び出せるようにするべきか？
    # とにかくエージェントの中でのコーディング量は極力減らすようにすることが大事
    # エージェントでは極力取引関連のビジネスロジックに注力するべき

    # 実際に取引するエージェントでは、AIに値を渡して判断させるだけにする

    # 移動平均を計算
    res = @mvs.map { |mv| mv.next_data(tick[:USDJPY].bid) }
    return if !res[0] || !res[1]

    # グラフに出力
    @graph << res
    # ゴールデンクロス/デッドクロスを判定
    @cross.next_data(*res)

    do_trade
  end

  def do_trade
    if @cross.cross_up?
      # ゴールデンクロス
      # 売り建玉があれば全て決済
      close_exist_positions(:sell)
      # 新規に買い
      broker.buy(:USDJPY, 1)
    elsif @cross.cross_down?
      # デッドクロス
      # 買い建玉があれば全て決済
      close_exist_positions(:buy)
      # 新規に売り
      broker.sell(:USDJPY, 1)
    end
  end

  def close_exist_positions(sell_or_buy)
    @broker.positions.each do |p|
      p.close if p.sell_or_buy == sell_or_buy
    end
  end

  # エージェントの状態を返却
  def state
    {
      mvs: @mvs.map { |mv| mv.state }
    }
  end

  # 永続化された状態から元の状態を復元する
  def restore_state(state)
    return unless state[:mvs]
    @mvs[0].restore_state(state[:mvs][0])
    @mvs[1].restore_state(state[:mvs][1])
  end

end
