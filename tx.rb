# A quick class to parse the log lines
# May 31 20:46:24 ams25 solana-rpc.sh[49084]: [2022-05-31T20:46:24.161879078Z INFO  solana_core::replay_stage] new fork:135888573 parent:135888571 (leader) root:135888527
# May 31 20:46:24 ams25 solana-rpc.sh[49084]: [2022-05-31T20:46:24.455250990Z INFO  solana_core::replay_stage] bank frozen: 135888573
# May 31 20:46:24 ams25 solana-rpc.sh[49084]: [2022-05-31T20:46:24.539460696Z INFO  solana_core::replay_stage] voting: 135888573 0
class TX
  attr_reader :log_string, :slot, :parent, :timestamp

  def initialize(log_line)
    @log_line = log_line
  end

  def parse_new_fork
    @slot = @log_line.between('new fork:', 'parent').strip.to_i
    @parent = @log_line.between('parent:', ' ').strip.to_i
    @timestamp = Time.parse(@log_line.between(']: [', 'INFO').strip)
  end

  def parse_frozen
    @slot = "#{@log_line}[E]".between('replay_stage] bank frozen:', '[E]').strip.to_i
    @timestamp = Time.parse(@log_line.between(']: [', 'INFO').strip)
  end

  def parse_voting
    @slot = @log_line.between('voting:', ' 0').strip.to_i
    @timestamp = Time.parse(@log_line.between(']: [', 'INFO').strip)
  end
end
