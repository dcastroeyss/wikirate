require_relative "../../../config/environment"

require_relative "relationship_answer_csv_row"
require_relative "relationship_metric_csv_row"
require_relative "../csv_file"

metrics_path = File.expand_path "../data/metrics.csv", __FILE__
answers_path = File.expand_path "../data/answers.csv", __FILE__

CSVFile.new(metrics_path, CSVRow::Structure::RelationshipMetricCSV)
       .import user: "Philipp Kuehl"
CSVFile.new(answers_path, CSVRow::Structure::RelationshipAnswerCSV)
       .import user: "Philipp Kuehl"
