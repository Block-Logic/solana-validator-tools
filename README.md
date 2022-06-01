# solana-validator-tools
Here are some of the tools that I use for Solana validator log analysis. Most of the script are written in Ruby and any recent version of Ruby on your system should work.

`process_log_slot_timing.rb` is a script that will process a validator or RPC log file and write slot timings to a CSV file.

`logs_20220601.1hour.txt.zip` contains a sample log for 1-hour of activity on June 1, 2022. This sample was taken from an RPC node.

To try the script, unzip the sample file and run  `ruby process_log_slot_timing.rb logs_20220601.1hour.txt` to write a CSV file. I have also included `logs_20220601.1hour.xls` for the instant gratification crowd.

### Footnotes:
- The Ruby script is WIP and I still need to refactor that + some performance optimizations. Nonetheless, this is quick & dirty & it works.
