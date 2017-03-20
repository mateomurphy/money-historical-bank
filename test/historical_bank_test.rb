# encoding: UTF-8

require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

describe Money::Bank::HistoricalBank do

  describe 'update_rates' do
    before do
      Money.infinite_precision = true
      @bank = Money::Bank::HistoricalBank.new
      #@bank.cache = @cache_path
      #@bank.update_rates
    end

    it "should store any rate stored for a date, and retrieve it when asked" do
      d1 = Date.new(2001,1,1)
      d2 = Date.new(2002,1,1)
      @bank.set_rate(d1, "USD", "EUR", 1.234)
      @bank.set_rate(d2, "GBP", "USD", 1.456)

      @bank.get_rate(d1, "USD", "EUR").must_equal 1.234
      @bank.get_rate(d2, "GBP", "USD").must_equal 1.456
    end

    it "should return the correct rate interpolated from existing pairs when asked" do
      d1 = Date.new(2001,1,1)
      @bank.set_rate(d1, "USD", "EUR", 1.234)
      @bank.set_rate(d1, "GBP", "USD", 1.456)

      @bank.get_rate(d1, "EUR", "USD").must_be_within_epsilon 1.0 / 1.234
      @bank.get_rate(d1, "GBP", "EUR").must_be_within_epsilon 1.456 * 1.234
    end

    it "should return the correct rates using exchange_with a date" do
      d1 = Date.new(2001,1,1)
      @bank.set_rate(d1, "USD", "EUR", 0.73062465)
      @bank.exchange_with(d1, Money.new(500000, 'EUR'), 'USD').cents.to_i.must_equal 684345
    end

    it "should return the correct rates using exchange_with no date (today)" do
      d1 = Date.today
      @bank.set_rate(d1, "USD", "EUR", 0.8)
      @bank.exchange_with(Money.new(500000, 'EUR'), 'USD').cents.must_equal 625000
    end

    it "should return the correct fractional rates" do
      d1 = Date.today
      @bank.set_rate(d1, "USD", "EUR", 0.8)
      @bank.exchange_with(Money.new(0.5, 'EUR'), 'USD').cents.must_equal 0.625
    end
  end

  describe 'no rates available yet' do
    before do
      @bank = Money::Bank::HistoricalBank.new
      @cache_path = "#{File.dirname(__FILE__)}/test.json"
    end

    it 'should download new rates from url' do
      source = Money::Bank::OpenExchangeRatesLoader.historical_url('2009-09-09')
      stub(@bank).open(source) { File.open @cache_path }
      d1 = Date.new(2009,9,9)

      rate = @bank.get_rate(d1, 'USD', 'EUR')
      rate.must_equal 0.73062465
    end
  end
end
