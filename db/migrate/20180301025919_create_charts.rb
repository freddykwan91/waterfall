class CreateCharts < ActiveRecord::Migration[5.1]
  def change
    create_table :charts do |t|
      t.string :title, default: "Chart Title"
      t.string :subtitle, default: "chart subtitle"
      t.text :notes
      t.integer :font_size, default: 12
      t.string :color, default: "$green"
      t.string :chart_image
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end