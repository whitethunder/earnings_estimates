require 'rubygems'
require 'rdoc/rdoc'
require 'open-uri'
require 'nokogiri'
require 'array_extensions'

class EarningsEstimates
#Potentially useful URLs
#http://finance.yahoo.com/q/ae?s=YHOO
#http://biz.yahoo.com/a/ba/a11.html
#http://www.zacks.com/research/earnings/today_eps.php
#TODO: Get market cap
#TODO: Analyze with # of analysts covering
#TODO: Figure out which metrics most closely follow price increase
#TODO: Analyze spread between high and low estimate

  attr_accessor :estimates, :ticker, :analysis
  MAX_REVISION_SCORE = 4

  def initialize(ticker)
    @ticker = ticker
    @estimates = {}
    @analysis = {}
  end

  # Analyzes earnings data and gives the security a score.
  def analyze
    #Score is based on:
    # % of times beating estimates
    # % by which estimates were beat
    # Bonus for upward revisions:
    #  4 points for 7 days
    #  3 points for 30 days
    #  2 points for 60 days
    #  1 point for 90 days
    #  Max score is 40
    percentages = percentages_to_f
    @analysis = {
      :average_beating_percentage => average_percent_beating(percentages),
      :beats                      => times_beating_estimates(percentages),
      :revision_points            => revision_score,
      :recently_revised           => nearest_quarters_upward_revised_recently?
    }
  end

  # Retrieves earnings data. Current source is MSN Money. Result is stored in @estimates.
  def fetch_earnings_data
    threads = []
    analysts_covering, earnings_surprise, eps_trend = nil, nil, nil
    threads << Thread.new { analysts_covering = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Symbol=#{@ticker}") }
    threads << Thread.new { earnings_surprise = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Page=EarningsSurprise&Symbol=#{@ticker}") }
    threads << Thread.new { eps_trend = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Page=ConsensusEPSTrend&Symbol=#{@ticker}") }
    threads.each { |t| t.join }
    @estimates[:analysts_covering], @estimates[:earnings_surprise], @estimates[:eps_trend] = analysts_covering, earnings_surprise, eps_trend
  end

  private

  def nearest_quarters_upward_revised_recently?
    0.upto(1) { |i| @estimates[:eps_trend]["Current Estimate"][i] > @estimates[:eps_trend]["7 Days Ago"][i] }
  end

  def parse_earnings_table(url)
    table_hash = {}
    page = Nokogiri::HTML(open(url))
    table = page.search("table.t1 tr").inject([]) { |accum, tr| accum << tr.children.map { |child| child.inner_text.strip } }
    table.each { |row| table_hash[strip_weird_chars(row[0])] = row.slice(1...row.size) }
    table_hash
  end

  def strip_weird_chars(header)
    #Take off all chars at the beginning of the string before the first uppercase char
    header.gsub(/^[^A-Z0-9]+/, '')
  end

  def percentages_to_f
    @estimates[:earnings_surprise]["Change"].map { |ch| ch[/(-?\d\.\d+)/, 1].to_f }
  end

  def times_beating_estimates(percentages)
    percentages.inject(0) { |accum, p| accum += p > 0 ? 1 : 0 }
  end

  def average_percent_beating(percentages)
    percentages.average
  end

  def revision_score
    score = 0
    0.upto(3) do |i|
      ["7 Days Ago", "30 Days Ago", "60 Days Ago", "90 Days Ago"].each do |period|
        score += (MAX_REVISION_SCORE - i) if @estimates[:eps_trend]["Current Estimate"][i] > @estimates[:eps_trend][period][i]
        score -= (MAX_REVISION_SCORE - i) if @estimates[:eps_trend]["Current Estimate"][i] < @estimates[:eps_trend][period][i]
      end
    end
    score
  end
end
