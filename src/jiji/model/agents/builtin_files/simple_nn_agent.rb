
require 'jiji/model/agents/agent'
require 'jiji/model/training/neural_net'

# ===人口知能を使うエージェントのサンプル
class NeuralNetAgent

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
      Property.new('long',  '長期移動平均線', 75),
      Property.new('neural','人工知能ファイルのパス', '/src/jiji/model/training/nn.dat'),
      Property.new('trade_time',  'トレードする間隔（秒）', 60)
    ]
  end

  def post_create
    # 移動平均の算出クラス
    # 共有ライブラリのクラスを利用。
    @mvs = [
      Signals::MovingAverage.new(@short.to_i),
      Signals::MovingAverage.new(@long.to_i)
    ]

    # ボリンジャーバンドの取得
    @bol = Signals::BollingerBands.new(@short.to_i, [3])

    # ROCの取得
    @roc = Signals::ROC.new(14)

    #傾きを取得
    @mom = Signals::Momentum.new(25)
    @vec = Signals::Vector.new(25)

    # 移動平均グラフ
    @graph = graph_factory.create('移動平均線',
      :rate, :average, ['#779999', '#557777'])

    # AIの器を作成する、もし学習結果がすでにあればそれを読み込む
    @nn = NeuralNet.load("#{Jiji::Utils::Requires.root}#{@neural}")

    @next_time = nil

    @bid_back = 0

    @input_data = nil
    @input_data_back = nil

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

    res25 = res[0]
    res200 = res[1]

    # ボリンジャーバンドを計算
    resbol = @bol.next_data(tick[:USDJPY].bid)

    resmom = @mom.next_data(tick[:USDJPY].bid)
    resvec = @vec.next_data(tick[:USDJPY].bid)
    resrsi = @roc.next_data(tick[:USDJPY].bid)

    # グラフに出力
    @graph << res

    if !resbol.nil? && !res200.nil?

      #ボラティリティ 上下3σの差
      p1 = resbol[0] - resbol[1]
      #モメンタム
      p2 = resmom
      #ベクター
      p3 = resvec
      #RSI
      p4 = resrsi
      #mov25とbidの差
      p5 = tick[:USDJPY].bid - res25
      #mov200とbidの差
      p6 = tick[:USDJPY].bid - res200


      p1 = p1.round(3)
      p2 = p2.round(3)
      p3 = p3.round(3)
      p4 = p4.round(3)
      p5 = p5.round(3)
      p6 = p6.round(3)

      @input_data = [p1,p2,p3,p4,p5,p6]

      if p1 != 0
        do_trade(tick)
      end
    end
  end

  def do_trade(tick)

    if @next_time == nil
      @next_time = tick.timestamp.to_i + @trade_time.to_i
    else
      if tick.timestamp.to_i > @next_time.to_i
        # 全て決済
        close_exist_positions(:sell)
        close_exist_positions(:buy)

        @next_time = tick.timestamp.to_i + @trade_time.to_i

        # 人工知能で取引方向を計算
        output = @nn.run @input_data

        if @bid_back < tick[:USDJPY].bid
          p7 = 1
        else
          p7 = 0
        end

        if !@input_data_back.nil?
          logger.debug "#{@input_data_back[0]},#{@input_data_back[1]},#{@input_data_back[2]},#{@input_data_back[3]},#{@input_data_back[4]},#{@input_data_back[5]},#{@input_data_back[6]},#{p7}"
        end

#        logger.debug "#{@input_data}"
#        logger.debug "#{output}"



        if output[0].to_f > 0.9
          broker.buy(:USDJPY, 1000)
#          logger.debug "buy: #{output}"
#          logger.debug "#{@input_data}"
        end

        if output[1].to_f > 0.9
          broker.sell(:USDJPY, 1000)
#          logger.debug "sell: #{output}"
#          logger.debug "#{@input_data}"
        end

        @bid_back = tick[:USDJPY].bid
        @input_data_back = @input_data

      end
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
