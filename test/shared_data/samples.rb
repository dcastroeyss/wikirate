
class SharedData
  module Samples
    # cards only exist in testing db
    def sample_note num=1
      notes = ["Death Star uses dark side of the Force", "Fruits are round"]
      Card[notes[num - 1]]
    end

    def sample_company index=0
      Card[SharedData::COMPANIES[index]]
    end

    def sample_topic index=0
      Card[SharedData::TOPICS[index]]
    end

    def sample_companies num=1, args={}
      Card.search args.merge(type_id: Card::WikirateCompanyID, limit: num)
    end

    def sample_topics num=1, args={}
      Card.search args.merge(type_id: Card::WikirateTopicID, limit: num)
    end

    def sample_analysis
      Card["Death Star+Force"]
    end

    def sample_metric value_type=:free_text
      metric_names = {
        free_text: "Jedi+Sith Lord in Charge",
        number: "Jedi+deadliness",
        category: "Jedi+disturbances in the Force",
        money: "Jedi+cost of planets destroyed"
      }
      Card[metric_names[value_type]]
    end

    def sample_project
      Card["Evil Project"]
    end

    def sample_source source=nil
      return Card.search(type_id: Card::SourceID, limit: 1).first unless source
      Card.search(type_id: Card::SourceID,
                  right_plus: ["link",
                               { content: "http://www.wikiwand.com/en/#{source}"}]).first
    end

    def sample_metric_value
      Card["Jedi+disturbances_in_the_Force+Death_Star+1977"]
    end
  end
end

