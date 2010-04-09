require 'rubygems'
require 'open-uri'
require 'nokogiri'

class EarningsEstimates
  def initialize
  end

  def fetch_earnings_data(ticker)
    analysts_covering = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Symbol=#{ticker}")
    earnings_surprise = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Page=EarningsSurprise&Symbol=#{ticker}")
    eps_trend = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Page=ConsensusEPSTrend&Symbol=#{ticker}")
  end

  def parse_earnings_table(url)
    page = Nokogiri::HTML(open(url))
    table = page.search("table.t1 tr").inject([]) { |accum, tr| accum << tr.children.map { |child| child.inner_text } }
  end
end
