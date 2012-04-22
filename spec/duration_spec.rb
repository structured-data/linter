$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::Literal::Duration do
  describe "#humanize" do
    {
      "PT1004199059S"             => "1004199059 seconds",
      "PT130S"                    => "130 seconds",
      "PT2M10S"                   => "2 minutes and 10 seconds",
      "P1DT2S"                    => "1 day and 2 seconds",
      "-P1Y"                      => "1 year ago",
      "P1Y2M3DT5H20M30.123S"      => "1 year 2 months 3 days 5 hours 20 minutes and 30.123 seconds",
      "-P1111Y11M23DT4H55M16.666S"=> "1111 years 11 months 23 days 4 hours 55 minutes and 16.666 seconds ago",
      "P2Y6M5DT12H35M30S"         => "2 years 6 months 5 days 12 hours 35 minutes and 30 seconds",
      "P1DT2H"                    => "1 day and 2 hours",
      "P20M"                      => "20 months",
      "PT20M"                     => "20 minutes",
      "P0Y20M0D"                  => "0 years 20 months and 0 days",
      "P0Y"                       => "0 years",
      "-P60D"                     => "60 days ago",
      "PT1M30.5S"                 => "1 minute and 30.5 seconds",
    }.each do |s, h|
      it "produces #{h}" do
        RDF::Literal::Duration.new(s).humanize.should == h
      end
    end
  end
end