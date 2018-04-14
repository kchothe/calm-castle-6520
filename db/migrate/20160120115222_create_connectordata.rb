class CreateConnectordata < ActiveRecord::Migration
  def change
    create_table :connectordata do |t|
      t.string :application_details
      t.string :mapping

      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true

      t.timestamps null: true
    end
  end
end
