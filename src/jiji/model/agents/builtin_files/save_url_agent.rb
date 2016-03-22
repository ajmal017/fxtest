
require 'jiji/model/agents/agent'
require 'open-uri'

class SaveUrlAgent

  include Jiji::Model::Agents::Agent

  def self.description
    <<-STR
 -指定のURLをファイルに保存します
      STR
  end

  # UIから設定可能なプロパティの一覧
  def self.property_infos
    [
      Property.new('target_url','保存したいファイルのURL', 'https://raw.githubusercontent.com/maxcus/fxtest/master/src/jiji/model/training/nn.dat'),
      Property.new('file_path','保存したいファイルのパス', '/src/jiji/model/training/nn.dat')
    ]
  end

  def post_create

    open("#{Jiji::Utils::Requires.root}#{@file_path}", 'wb'){|saved_file|
      open(@target_url, 'rb'){|read_file|
        saved_file.write(read_file.read)
      }
    }

  end

  # 次のレートを受け取る
  def next_tick(tick)
  end

  # エージェントの状態を返却
  def state
  end

  # 永続化された状態から元の状態を復元する
  def restore_state(state)
  end

end
