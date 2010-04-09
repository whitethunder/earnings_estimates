require 'rubygems'
require 'open-uri'
require 'nokogiri'

class EarningsEstimates
  def initialize(ticker)
    @ticker = ticker
  end

  def fetch_earnings_data
    threads = []
    results = {}
    threads << Thread.new { results[:analysts_covering] = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Symbol=#{@ticker}") }
    threads << Thread.new { results[:earnings_surprise] = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Page=EarningsSurprise&Symbol=#{@ticker}") }
    threads << Thread.new { results[:eps_trend] = parse_earnings_table("http://moneycentral.msn.com/investor/invsub/analyst/earnest.asp?Page=ConsensusEPSTrend&Symbol=#{@ticker}") }
    threads.each { |t| t.join }
    results
  end

  private

  def parse_earnings_table(url)
    page = Nokogiri::HTML(open(url))
    table = page.search("table.t1 tr").inject([]) { |accum, tr| accum << tr.children.map { |child| child.inner_text } }
  end
end
