# Usage:
# ruby process_log_slot_timing.rb [Uncompressed log file]
# Then look at the output CSV file.

require 'time'
require 'csv'
require_relative 'monkey_patches.rb'
require_relative 'tx.rb'

input_file = ARGV[0]

slot_times = {}

File.foreach(input_file) do |line|
  tx = TX.new(line)

  if line.include?('new fork:')
    tx.parse_new_fork
    slot_times[tx.slot] = {} if slot_times[tx.slot].nil?
    slot_times[tx.slot][:parent] = tx.parent
    slot_times[tx.slot][:new_fork_at] = tx.timestamp
  elsif line.include?('replay_stage] bank frozen:')
    tx.parse_frozen
    slot_times[tx.slot] = {} if slot_times[tx.slot].nil?
    slot_times[tx.slot][:frozen_at] = tx.timestamp
    unless slot_times[tx.slot][:new_fork_at].nil?
      slot_times[tx.slot][:et_frozen] =
      slot_times[tx.slot][:frozen_at] - slot_times[tx.slot][:new_fork_at]
    end
  elsif line.include?('voting:')
    tx.parse_voting
    slot_times[tx.slot] = {} if slot_times[tx.slot].nil?
    slot_times[tx.slot][:voting_at] = tx.timestamp
    unless slot_times[tx.slot][:new_fork_at].nil?
      slot_times[tx.slot][:et_total] =
      slot_times[tx.slot][:voting_at] - slot_times[tx.slot][:new_fork_at]
    end
    unless slot_times[tx.slot][:frozen_at].nil?
      slot_times[tx.slot][:et_voting] =
      slot_times[tx.slot][:voting_at] - slot_times[tx.slot][:frozen_at]
    end
  end
end

# Calculate the latency between the current new_fork message and the parent
# new fork message.
slot_times.each do |k,v|
  # puts "#{k} => #{v.inspect}"
  slot_times[k][:latency_new_fork] = \
    v[:new_fork_at] - slot_times[v[:parent]][:new_fork_at] \
    unless slot_times[v[:parent]].nil? || v[:voting_at].nil?
end

# calculate some stats
elapsed_times_frozen = slot_times.map{|k,v| v[:et_frozen] }.compact
elapsed_times_voting = slot_times.map{|k,v| v[:et_voting] }.compact
elapsed_times_total  = slot_times.map{|k,v| v[:et_total] }.compact
latencies_new_fork = slot_times.map{|k,v| v[:latency_new_fork] }.compact
# puts elapsed_times_frozen.inspect
new_leader_new_fork_latencies = []

CSV.open("#{input_file}.csv", 'w') do |csv|
  csv << %w[slot parent new_fork_at frozen_at voting_at elapsed_time_frozen elapsed_time_voting elapsed_time_total latency_new_fork slot_sequence comments]
  # Stats Header
  csv << [
    'Average',nil,nil,nil,nil,
    (elapsed_times_frozen.sum/elapsed_times_frozen.length.to_f).round(6),
    (elapsed_times_voting.sum/elapsed_times_voting.length.to_f).round(6),
    (elapsed_times_total.sum/elapsed_times_total.length.to_f).round(6),
    (latencies_new_fork.sum/latencies_new_fork.length.to_f).round(6),
    nil,
    nil
  ]

  csv << [
    'Median',nil,nil,nil,nil,
    elapsed_times_frozen.median.round(6),
    elapsed_times_voting.median.round(6),
    elapsed_times_total.median.round(6),
    latencies_new_fork.median.round(6),
    nil,
    nil
  ]

  # Detail Rows
  slot_times.each do |k,v|
    new_fork_at_iso = v[:new_fork_at].iso8601(6) rescue nil
    frozen_at_iso = v[:frozen_at].iso8601(6) rescue nil
    voting_at_iso = v[:voting_at].iso8601(6) rescue nil

    # Comments
    comments = []
    if k.modulo(4).zero? && !voting_at_iso.nil?
      comments << 'New Leader'
      new_leader_new_fork_latencies << v[:latency_new_fork]
    end
    if voting_at_iso.nil?
      comments << 'Skipped Slot'
    end

    csv << [
      k,
      v[:parent],
      new_fork_at_iso,
      frozen_at_iso,
      voting_at_iso,
      v[:et_frozen].nil? ? nil : v[:et_frozen].round(6),
      v[:et_voting].nil? ? nil : v[:et_voting].round(6),
      v[:et_total].nil? ? nil : v[:et_total].round(6),
      v[:latency_new_fork].nil? ? nil : v[:latency_new_fork].round(6),
      k.modulo(4),
      comments.join(', ')
    ]
  end
end
puts ''
puts "Average new_leader_new_fork_latencies is #{(new_leader_new_fork_latencies.sum / new_leader_new_fork_latencies.length.to_f).round(6)}"
puts "Median new_leader_new_fork_latencies is #{new_leader_new_fork_latencies.median.round(6)}"
