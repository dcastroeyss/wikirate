require_relative "../../support/shared_csv_data"
require_relative "../../support/shared_csv_import"


describe Card::Set::Type::AnswerImportFile, type: :controller do
  routes { Decko::Engine.routes }
  before { @controller = CardController.new }

  describe "view: import_table" do
    include_context "csv import" do
      let(:csv_row_class) { CSVRow::Structure::AnswerCSV }
      let(:import_card) { Card["answer import test"] }
      let(:data) do
        {
          exact_match: ["Jedi+disturbances in the Force", "Death Star", "2017", "yes", "http://google.com", ""],
          alias_match: ["Jedi+disturbances in the Force", "Google", "2017", "yes", "http://google.com", ""],
          partial_match: ["Jedi+disturbances in the Force", "Sony", "2017", "yes", "http://google.com", ""],
          no_match: ["Jedi+disturbances in the Force", "New Company", "2017", "yes", "http://google.com", ""],
          not_a_metric: ["Not a metric", "Monster Inc", "2017", "yes", "http://google.com", ""]
        }
      end
    end

    it "sorts by match type" do
      table = import_card_with_data.format(:html)._render_import_table
      expect(table).to have_tag :table do
        with_tag :tbody do
          with_text /Not a metric.+New Company.+Sony.+Google.+Death Star/m
        end
      end
    end
  end

  describe "import csv file" do
    include_context "csv import" do
      let(:csv_row_class) { CSVRow::Structure::AnswerCSV }
      let(:import_card) { Card["answer import test"] }
      let(:data) do
        {
          exact_match: ["Jedi+disturbances in the Force", "Death Star", "2017", "yes", "http://google.com", "chch"],
          alias_match: ["Jedi+disturbances in the Force", "Google", "2017", "yes", "http://google.com", ""],
          partial_match: ["Jedi+disturbances in the Force", "Sony", "2017", "yes", "http://google.com", ""],
          no_match: ["Jedi+disturbances in the Force", "New Company", "2017", "yes", "http://google.com", ""],
          not_a_metric: ["Not a metric", "Monster Inc", "2017", "yes", "http://google.com", ""],
          not_a_company: ["Jedi+disturbances in the Force", "A", "2017", "yes", "http://google.com/4", ""],
          company_missing: ["Jedi+disturbances in the Force", "", "2017", "yes", "http://google.com/5", ""],
          missing_and_invalid: ["Not a metric", "", "2017", "yes", "http://google.com/6", ""],
          conflict_same_value_same_source: ["Jedi+disturbances in the Force", "Death Star", "2000", "yes", "http://www.wikiwand.com/en/Opera", ""],
          conflict_same_value_different_source: ["Jedi+disturbances in the Force", "Death Star", "2000", "yes", "http://google.com/9", ""],
          conflict_different_value: ["Jedi+disturbances in the Force", "Death Star", "2000", "no", "http://google.com/10", ""],
          invalid_value: ["Jedi+disturbances in the Force", "Death Star", "2017", "100", "http://google.com/11", ""],
          monster_badge_1: ["Jedi+disturbances in the Force", "Monster Inc.", "2000", "yes", "http://google.com/12", ""],
          monster_badge_2: ["Jedi+disturbances in the Force", "Monster Inc.", "2001", "yes", "http://google.com/13", ""],
          monster_badge_3: ["Jedi+disturbances in the Force", "Monster Inc.", "2002", "yes", "http://google.com/14", ""]
        }
      end
    end

    let(:metric) { "Jedi+disturbances in the Force" }
    let(:year) { "2017" }

    include_context "answer import" do
      let(:company_row) { 1 }
      let(:value_row) { 3 }
    end

    before do
      login_as "joe_admin"
    end

    example "create new import card and import", as_bot: true do
      real_csv_file = File.open File.expand_path("../../../support/test.csv", __FILE__)
      import_card = create "test import", type_id: Card::AnswerImportFileID,
                           answer_import_file: real_csv_file
      expect_card("test import").to exist.and have_file.of_size(be > 400)
      expect_card("Jedi+disturbances in the Force+Death Star+2017+value").not_to exist
      params = import_params exact_match: { match_type: :exact }
      post :update, xhr: true, params: params.merge(id: "~#{import_card.id}")
      expect_card("Jedi+disturbances in the Force+Death Star+2017+value").to exist
    end

    it "imports answer" do
      trigger_import :exact_match
      expect_answer_created :exact_match
    end

    it "imports comment" do
      trigger_import :exact_match
      expect(Card[answer_name(:exact_match), :discussion]).to have_db_content(/chch/)
    end

    it "marks value in action as imported" do
      trigger_import :exact_match
      action_comment = value_card(:exact_match).actions.last.comment
      expect(action_comment).to eq "imported"
    end

    it "marks value in answer table as imported" do
      trigger_import :exact_match
      answer_id = answer_card(:exact_match).id
      answer = Answer.find_by_answer_id(answer_id)
      expect(answer.imported).to eq true
    end

    def badge_names
      badges = Card.fetch "Joe Admin", :metric_value, :badges_earned
      badges.item_names
    end

    it "awards badges" do
      expect(badge_names).not_to include "Monster Inc.+Researcher+company badge"
      trigger_import :monster_badge_1, :monster_badge_2, :monster_badge_3
      expect(badge_names).to include "Monster Inc.+Researcher+company badge"
    end

    it "imports others if one fails" do
      trigger_import :exact_match, :invalid_value
      expect_card("Jedi+disturbances in the Force+Death Star+2017+value")
        .to exist.and have_db_content("yes")
    end

    describe "duplicates" do

    end

    context "company correction name is filled" do
      it "uses the corrected company name" do
        trigger_import no_match: { corrections: { company: "corrected company" } }
        expect(Card[metric, "corrected company", year])
          .to exist.and have_a_field(:value).with_content("yes")
      end

      context "no match" do
        it "adds company name in file to corrected company's aliases" do
          trigger_import no_match: { match_type: :none,
                                              corrections: { company: "corrected company" } }

          expect(Card["corrected company", :aliases].item_names).to include "New Company"
        end
      end

      context "partial match" do
        it "adds company name in file to corrected company's aliases" do
          trigger_import partial_match: { match_type: :partial,
                                          corrections: { company: "corrected company" } }
          expect(Card["corrected company", :aliases].item_names).to include "Sony"
        end
      end
    end
  end

  example "empty import" do

  end
end
