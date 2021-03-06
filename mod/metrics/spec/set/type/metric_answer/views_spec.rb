# -*- encoding : utf-8 -*-

RSpec.describe Card::Set::Type::MetricAnswer::Views do
  describe "#humanized_number" do
    def humanize number
      Card["Jedi+deadliness+Death Star+1977"].format.humanized_number(number)
    end

    specify do
      expect(humanize("1_000_001")).to eq "1M"
    end
    specify do
      expect(humanize("0.00000123345")).to eq "0.00000123"
    end
    specify do
      expect(humanize("0.001200")).to eq "0.0012"
    end
    specify do
      expect(humanize("123.4567")).to eq "123.5"
    end
  end

  describe "view :concise" do
    context "with multi category metric" do
      subject do
        render_view :concise, name: "Joe User+big multi+Sony Corporation+2010"
      end

      it "has comma separated list of values" do
        is_expected.to have_tag "span.metric-value", "1, 2"
      end
      it "has correct year" do
        is_expected.to have_tag "span.metric-year", /2010/
      end
      it "has options" do
        is_expected.to have_tag "span.metric-unit", /1,2,3,4,5,6,7,8,9,10,11/
      end
    end

    context "with single category metric" do
      subject do
        render_view :concise, name: "Joe User+big single+Sony Corporation+2010"
      end

      it "has value" do
        is_expected.to have_tag "span.metric-value", "4"
      end
      it "has correct year" do
        is_expected.to have_tag "span.metric-year", /2010/
      end
      it "has options" do
        is_expected.to have_tag "span.metric-unit", /1,2,3,4,5,6,7,8,9,10,11/
      end
    end
  end
end
