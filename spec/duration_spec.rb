$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/model/literal/duration'

describe RDF::Literal::Duration do
  describe "initialize" do
    it "creates given a Hash" do
      RDF::Literal::Duration.new(:seconds => 10, :minutes => 1).to_i.should == 70
    end
  end


  describe "#to_f" do
    {
      "PT130S"                    => 130,
      "PT130M"                    => 130*60,
      "PT130H"                    => 130*3600,
      "P130D"                     => 130*24*3600,
      "P130M"                     => 130*30*24*3600,
      "P130Y"                     => 130*365*24*3600,
      "PT2M10S"                   => (2*60+10),
      "P1DT2S"                    => (1*3600*24+2),
      "P1DT2H"                    => 26*3600,
      "P0Y20M0D"                  => 20*30*24*3600,
      "P0Y"                       => 0,
      "-P60D"                     => -60*24*3600,
      "PT1M30.5S"                 => 60+30.5,
      "P20M"                      => 20*30*24*3600,
      "PT20M"                     => 20*60,
      "-P1Y"                      => (-365*3600*24),
      "PT1004199059S"             => 1004199059,
      "P1Y2M3DT5H20M30.123S"      => ((365+60+3)*3600*24+5*3600+20*60+30.123),
      "-P1111Y11M23DT4H55M16.666S"=> -((((1111*365+11*30+23)*24)+4)*3600+55*60+16.666),
      "P2Y6M5DT12H35M30S"         => (((2*365+6*30+5)*24)+12)*3600+35*60+30,
    }.each do |s, f|
      it "parses #{s}" do
        RDF::Literal::Duration.new(s).to_f.should == f
      end
    end
  end

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